// locationCapture.m
//
// This file contains the implementation for our LocationCapture React Native
// module.

#import "LocationCapture.h"
#import "UploadQueue.h"
#import "TMReachability.h"
#import "LocationStore.h"

// ##########################################################################
//
// Should we write debugging messages to the console?

#define DEBUG_MODE 0

// ##########################################################################
//
// The following enumerator type defines the various types of connection which
// can be used for uploading data to the remote server:

typedef enum {
    kUploadWifiOnly,
    kUploadWhenAnyConnection
} UploadConnectionType;

// ##########################################################################
//
// The following enumerator type defines the various HTTP request formats we
// support for uploading data to the remote server:

typedef enum {
    kUploadRequestFormatJSON,
    kUploadRequestFormatFormURLEncoded
} UploadRequestFormat;

// ##########################################################################
//
// Our private interface:

@interface LocationCapture ()

@property (atomic, strong) CLLocationManager*     cur_location_manager;
@property (atomic, copy)   RCTPromiseResolveBlock cur_location_resolve;
@property (atomic, copy)   RCTPromiseRejectBlock  cur_location_reject;
@property (atomic, strong) NSNumber*              time_filter;
@property (atomic, strong) NSNumber*              distance_filter;
@property (atomic, assign) BOOL                   upload_enabled;
@property (atomic, strong) NSString*              upload_url;
@property (atomic, assign) UploadConnectionType   upload_connection_type;
@property (atomic, strong) NSNumber*              upload_frequency;
@property (atomic, assign) UploadRequestFormat    upload_request_format;
@property (atomic, strong) NSString*              upload_locations_param;
@property (atomic, strong) NSDictionary*          upload_extra_params;
@property (atomic, assign) BOOL                   upload_field_timestamp;
@property (atomic, assign) BOOL                   upload_field_latitude;
@property (atomic, assign) BOOL                   upload_field_longitude;
@property (atomic, assign) BOOL                   upload_field_accuracy;
@property (atomic, assign) BOOL                   upload_field_heading;
@property (atomic, assign) BOOL                   upload_field_speed;
@property (atomic, assign) BOOL                   in_background;
@property (atomic, strong) CLLocationManager*     background_location_manager;
@property (atomic, strong) NSDate*                last_update;
@property (atomic, strong) NSDate*                last_upload;

// ==========================================================================
//
// init
//
//     Initialise our module.

- (id) init;

// ==========================================================================
//
// methodQueue
//
//     Return the method queue to use for running our module.  We override this
//     to force the module to run using the main thread so that the location
//     manager will work.

- (dispatch_queue_t) methodQueue;

// ==========================================================================
//
// send_notification
//
//     Send a notification to our Javascript code that we've added one or more
//     locations to the location store.
//
//     Note that we only send notifications while the app is in the foreground.

- (void) send_notification;

// ==========================================================================
//
// add_to_upload_queue:
//
//     Add the given location to the upload queue.
//
//     The location dictionary should have the following entries:
//
//          timestamp
//          latitude
//          longitude
//          accuracy
//          heading
//          speed
//
//     All the fields should be NSNumber objects.  Note that the timestamp is
//     measured as the number of seconds since the 1st of January, 1970.

- (void) add_to_upload_queue:(NSDictionary*)location;

// ==========================================================================
//
// get_upload_server
//
//     Extract the server name from our upload URL.
//
//     We extract the server (host) name from self.upload_url.  If
//     self._upload_url hasn't been set, we return nil.

- (NSString*) get_upload_server;

// ==========================================================================
//
// should_upload_to_server
//
//     Return |YES| if we can currently upload data to the server.
//
//     We calculate the current connection to the remote server, and compare
//     this against self.upload_connection_type to see if we should currently
//     upload data.

- (BOOL) should_upload_to_server;

// ==========================================================================
//
// send_upload_queue_to_server
//
//     Attempt to send the contents of the upload queue to the configured
//     server.
//
//     Note that the upload queue is cleared by this method, but if the
//     background geolocator is unable to access the remote server (eg, because
//     of a lack of cellphone connectivity), then the previous contents of the
//     queue will be added back in so the updates can be re-sent at a later
//     time.  This ensures that nothing is lost, and updates continue to be
//     queued while there is no network connectivity.

- (void) send_upload_queue_to_server;

// ==========================================================================
//
// date_to_rfc_3339_string:
//
//     Convert an NSDate object into an RFC-3339 format string representing
//     that date and time in the user's local timezone.

- (NSString*) date_to_rfc_3339_string:(NSDate*)date;

// ==========================================================================
//
// build_json_request_for:
//
//     Construct an HTTP "POST" request to use for uploading the given
//     locations to the remote server, using JSON encoding for the parameters.
//
//     We construct the appropriate NSURLRequest object to upload the locations
//     in JSON format using an HTTP "POST" request.

- (NSURLRequest*) build_json_request_for:(NSArray*)locations;

// ==========================================================================
//
// build_form_request_for:
//
//     Construct an HTTP "POST" request to use for uploading the given
//     locations to the remote server, using URL-encoded form parameters.
//
//     We construct the appropriate NSURLRequest object to upload the locations
//     as a URL-encoded form using an HTTP "POST" request.

- (NSURLRequest*) build_form_request_for:(NSArray*)locations;

// ==========================================================================
//
// locations_for_upload:
//
//     Given an array of locations, return an array with only the fields to be
//     uploaded.
//
//     We return an NSArray of locations, where each array entry is an
//     NSDictionary containing just the fields to be uploaded.

- (NSArray*) locations_for_upload:(NSArray*)locations;

// ==========================================================================
//
// on_enter_background
//
//     Respond to the app being moved into the background.
//
//     When the app moves into the background, we simply start queuing the
//     location updates and errors, so we can pass them on to the app when we
//     move into the foreground again.

- (void) on_enter_background;

// ==========================================================================
//
// on_enter_foreground
//
//     Respond to the app being moved into the foreground.
//
//     Any queued location updates or errors will be sent to the relevant
//     handler function for processing.

- (void) on_enter_foreground;

// ==========================================================================
//
// connection_to_server:
//
//     Return the type of connection we currently have to the given server.
//
//     One of the following string values will be returned:
//
//         "NONE"
//
//             There is currently no connection to the given server.
//
//         "WIFI"
//
//             We have a WIFI connection to the given server.
//
//         "CELLULAR"
//
//             We have a cellular connection to the given server.

- (NSString*) connection_to_server:(NSString*)server_name;

// ==========================================================================

@end

// ##########################################################################

@implementation LocationCapture

RCT_EXPORT_MODULE();

// ==========================================================================
// ==                                                                      ==
// ==                   I N T E R N A L   M E T H O D S                    ==
// ==                                                                      ==
// ==========================================================================

- (id) init {

    if (self = [super init]) {
        self.cur_location_manager        = nil;
        self.cur_location_resolve        = nil;
        self.cur_location_reject         = nil;
        self.time_filter                 = nil;
        self.distance_filter             = nil;
        self.upload_enabled              = NO;
        self.upload_url                  = nil;
        self.upload_connection_type      = kUploadWifiOnly;
        self.upload_frequency            = 0;
        self.upload_request_format       = kUploadRequestFormatJSON;
        self.upload_locations_param      = @"locations";
        self.upload_extra_params         = nil;
        self.upload_field_timestamp      = YES;
        self.upload_field_latitude       = YES;
        self.upload_field_longitude      = YES;
        self.upload_field_accuracy       = NO;
        self.upload_field_heading        = NO;
        self.upload_field_speed          = NO;
        self.in_background               = NO;
        self.background_location_manager = nil;
        self.last_update                 = nil;
        self.last_upload                 = nil;

        NSNotificationCenter* listener = [NSNotificationCenter defaultCenter];

        [listener addObserver:self
                     selector:@selector(on_enter_background)
                         name:UIApplicationDidEnterBackgroundNotification
                       object:nil];

        [listener addObserver:self
                     selector:@selector(on_enter_foreground)
                         name:UIApplicationWillEnterForegroundNotification
                       object:nil];

        return self;
    } else {
        return nil;
    }
}

// ==========================================================================

- (dispatch_queue_t) methodQueue {

    return dispatch_get_main_queue();
}

// ==========================================================================

- (void) send_notification {

    if (!self.in_background) {
        [self sendEventWithName:@"location_received" body:nil];
    }
}

// ==========================================================================

- (void) add_to_upload_queue:(NSDictionary*)location {

    double    secs      = [location[@"timestamp"] doubleValue];
    NSDate*   date      = [NSDate dateWithTimeIntervalSince1970:secs];
    NSString* timestamp = [self date_to_rfc_3339_string:date];

    NSDictionary* loc = @{@"timestamp" : timestamp,
                          @"latitude"  : location[@"latitude"],
                          @"longitude" : location[@"longitude"],
                          @"accuracy"  : location[@"accuracy"],
                          @"heading"   : location[@"heading"],
                          @"speed"     : location[@"speed"]};

    [[UploadQueue sharedQueue] add:loc];
}

// ==========================================================================

- (NSString*) get_upload_server {

    if (self.upload_url != nil) {
        NSURLComponents* components = [[NSURLComponents alloc]
                                       initWithString:self.upload_url];
        return components.host;
    } else {
        return nil;
    }
}

// ==========================================================================

- (BOOL) should_upload_to_server {

    // Start by seeing if enough time has passed to match the specified upload
    // frequency.

    NSDate* now = [NSDate date];
    if (self.last_upload != nil) {
        int secs_ago = (int)[now timeIntervalSinceDate:
                                            self.last_upload];
        if (secs_ago < [self.upload_frequency intValue]) {
            return NO;
        }
    }

    // Now check to see if we have the right type of connection to the server
    // to upload, based on self.upload_connection_type.

    NSString* server          = [self get_upload_server];
    NSString* connection_type = [self connection_to_server:server];

    if (self.upload_connection_type == kUploadWhenAnyConnection) {
        if ([connection_type isEqualToString:@"WIFI"]) {
            return YES;
        } else if ([connection_type isEqualToString:@"CELLULAR"]) {
            return YES;
        } else {
            return NO;
        }
    } else if (self.upload_connection_type == kUploadWifiOnly) {
        if ([connection_type isEqualToString:@"WIFI"]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

// ==========================================================================

- (void) send_upload_queue_to_server {

    NSArray* locations = [[UploadQueue sharedQueue] flush];

    if ([locations count] == 0) {
        return;
    }

    NSURLRequest* request = nil;
    if (self.upload_request_format == kUploadRequestFormatJSON) {
        request = [self build_json_request_for:locations];
    } else if (self.upload_request_format ==
                                    kUploadRequestFormatFormURLEncoded) {
        request = [self build_form_request_for:locations];
    } else {
        NSLog(@"Invalid request format!");
    }

    if (request == nil) {
        return;
    }

    void (^completion_handler)(NSData*, NSURLResponse*, NSError*);
    completion_handler = ^(NSData* data,
                           NSURLResponse* response,
                           NSError* error) {

        if (error != nil) {
            // We received an error response.  Note that this only applies to
            // client-side errors.

#if DEBUG_MODE
            NSLog(@"Failed to upload locations to server, error = %@", error);
#endif
            [[UploadQueue sharedQueue] restore:locations];
        } else {
            // We didn't receive an error.  Note that this doesn't mean that
            // the request was successful; we have to check the status code to
            // see what actually happened.
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse* http_response = (NSHTTPURLResponse*)response;
                NSInteger status_code = [http_response statusCode];
                if (status_code != 201) {
#if DEBUG_MODE
                    NSLog(@"Upload request failed with a %d code", status_code);
                    NSString* sData = [[NSString alloc]
                                        initWithData:data
                                            encoding:NSUTF8StringEncoding];
                    NSLog(@"data = %@", sData);
#endif
                    [[UploadQueue sharedQueue] restore:locations];
                } else {
                    // Success!
#if DEBUG_MODE
                    NSLog(@"Successfully uploaded locations to server.");
#endif
                    self.last_upload = [NSDate date];
                }
            }
        }
    };

    NSURLSessionDataTask* task;
    task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                           completionHandler:completion_handler];
    [task resume];
}

// ==========================================================================
//
// This code is taken from: https://gist.github.com/popthestack/5877965

- (NSString*) date_to_rfc_3339_string:(NSDate*)date {

    NSTimeZone* localTimeZone = [NSTimeZone systemTimeZone];
    NSDateFormatter* rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale* enUSPOSIXLocale = [[NSLocale alloc]
                                 initWithLocaleIdentifier:@"en_US_POSIX"];

    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
    [rfc3339DateFormatter setTimeZone:localTimeZone];

    NSString* dateString = [rfc3339DateFormatter stringFromDate:date];
    return dateString;
}

// ==========================================================================

- (NSURLRequest*) build_json_request_for:(NSArray*)locations {

    // Assemble our POST parameters.

    NSArray* locations_to_upload = [self locations_for_upload:locations];
    NSMutableDictionary* post_data = [[NSMutableDictionary alloc] init];
    [post_data addEntriesFromDictionary:self.upload_extra_params];
    [post_data setObject:locations_to_upload
                  forKey:self.upload_locations_param];

    // Encode the POST parameters into a JSON-format string.

    NSError* error;
    NSData* encoded_data =
        [NSJSONSerialization dataWithJSONObject:post_data
                                        options:0
                                          error:&error];

    if (error != nil) {
        NSLog(@"Unable to prepare data for posting: %@", error);
        return nil;
    }

    // Finally, build our request.

    NSURL* url = [NSURL URLWithString:self.upload_url];
    NSMutableURLRequest* request =
        [NSMutableURLRequest requestWithURL:url
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:10.0];

    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:encoded_data];

    return request;
}

// ==========================================================================

- (NSURLRequest*) build_form_request_for:(NSArray*)locations {

    // Create the body of our request as an application/x-www-form-urlencoded
    // string.

    NSMutableArray* parts = [NSMutableArray array];

    for (NSString* key in self.upload_extra_params) {
        NSString* value = [self.upload_extra_params objectForKey:key];
        NSString* encoded_key =
            [key stringByAddingPercentEscapesUsingEncoding:
                                                  NSUTF8StringEncoding];
        NSString* encoded_value =
            [value stringByAddingPercentEscapesUsingEncoding:
                                                  NSUTF8StringEncoding];
        NSString* part = [NSString stringWithFormat:@"%@=%@",
                                                    encoded_key,
                                                    encoded_value];
        [parts addObject:part];
    }

    NSArray* locations_to_upload = [self locations_for_upload:locations];

    for (NSDictionary* location in locations_to_upload) {
        for (NSString* key in location) {
            id value = [location objectForKey:key];
            NSString* string_value = [NSString stringWithFormat:@"%@",
                                                                value];
            NSString* field = [NSString stringWithFormat:
                                            @"%@[%@]",
                                            self.upload_locations_param,
                                            key];
            NSString* encoded_field =
                [field stringByAddingPercentEscapesUsingEncoding:
                                                      NSUTF8StringEncoding];
            NSString* encoded_value =
                [string_value stringByAddingPercentEscapesUsingEncoding:
                                                      NSUTF8StringEncoding];
            NSString* part = [NSString stringWithFormat:@"%@=%@",
                                                        encoded_field,
                                                        encoded_value];
            [parts addObject:part];
        }
    }

    NSString* encoded_string = [parts componentsJoinedByString:@"&"];
    NSData* encoded_data = [encoded_string dataUsingEncoding:
                                                    NSUTF8StringEncoding];

    // Build the request itself.

    NSURL* url = [NSURL URLWithString:self.upload_url];
    NSMutableURLRequest* request =
        [NSMutableURLRequest requestWithURL:url
                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                            timeoutInterval:10.0];

    [request setHTTPMethod:@"POST"];
    [request      addValue:@"application/x-www-form-urlencoded"
        forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:encoded_data];
    return request;
}

// ==========================================================================

- (NSArray*) locations_for_upload:(NSArray*)locations {

    NSMutableArray* locations_to_upload = [[NSMutableArray alloc] init];

    for (NSDictionary* src_loc in locations) {
        NSMutableDictionary* dst_loc = [[NSMutableDictionary alloc] init];

        if (self.upload_field_timestamp) {
            dst_loc[@"timestamp"] = src_loc[@"timestamp"];
        }
        if (self.upload_field_latitude) {
            dst_loc[@"latitude"] = src_loc[@"latitude"];
        }
        if (self.upload_field_longitude) {
            dst_loc[@"longitude"] = src_loc[@"longitude"];
        }
        if (self.upload_field_accuracy) {
            dst_loc[@"accuracy"] = src_loc[@"accuracy"];
        }
        if (self.upload_field_heading) {
            dst_loc[@"heading"] = src_loc[@"heading"];
        }
        if (self.upload_field_speed) {
            dst_loc[@"speed"] = src_loc[@"speed"];
        }

        [locations_to_upload addObject:dst_loc];
    }

    return locations_to_upload;
}

// ==========================================================================

- (void) on_enter_background {

    self.in_background = YES;
}

// ==========================================================================

- (void) on_enter_foreground {

    self.in_background = NO;
}

// ==========================================================================

- (NSString*) connection_to_server:(NSString*)server_name {

    TMReachability* reachability = [TMReachability
                                        reachabilityWithHostName:server_name];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    [reachability stopNotifier];

    if (status == NotReachable) {
        return @"NONE";
    } else if (status == ReachableViaWiFi) {
        return @"WIFI";
    } else if (status == ReachableViaWWAN) {
        return @"CELLULAR";
    } else {
        return @"NONE"; // Best fallback?
    }
}

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================
//
// get_current
//
//     Retrieve the current GPS location.

RCT_REMAP_METHOD(get_current, resolver:(RCTPromiseResolveBlock)resolve
                              rejecter:(RCTPromiseRejectBlock)reject) {

    // Check that we're allowed to access the user's location.

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if ((status == kCLAuthorizationStatusRestricted) ||
        (status == kCLAuthorizationStatusDenied)) {
        // The user refused to let us access their location.
        reject(@"DENIED", @"Unable to turn on locations", nil);
        return;
    }

    // Create our location manager if we haven't already got one.

    if (self.cur_location_manager == nil) {
        self.cur_location_manager = [[CLLocationManager alloc] init];
        self.cur_location_manager.delegate = self;
    }

    // If necessary, ask the user for permission to monitor their location.

    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.cur_location_manager requestWhenInUseAuthorization];
    }

    // Check that location services have been enabled.

    if (![CLLocationManager locationServicesEnabled]) {
        // Location services are not enabled for some reason.
        reject(@"UNAVAILABLE", @"Location services are not available", nil);
        return;
    }

    self.cur_location_resolve = resolve;
    self.cur_location_reject  = reject;

    self.cur_location_manager.desiredAccuracy = kCLLocationAccuracyBest;
    self.cur_location_manager.activityType    = CLActivityTypeFitness;

    [self.cur_location_manager requestLocation];
}

// ==========================================================================
//
// configure
//
//     Configure the operation of the location capture module.

RCT_EXPORT_METHOD(configure:(NSDictionary*)options) {

    if (options[@"time_filter"] != nil) {
        self.time_filter = options[@"time_filter"];
    }

    if (options[@"distance_filter"] != nil) {
        self.distance_filter = options[@"distance_filter"];
    }

    if (options[@"upload_enabled"] != nil) {
        self.upload_enabled = [options[@"upload_enabled"] boolValue];
    }

    if (options[@"upload_url"] != nil) {
        self.upload_url = options[@"upload_url"];
    }

    if (options[@"upload_connection_type"] != nil) {
        NSString* connection_type = options[@"upload_connection_type"];
        if ([connection_type isEqualToString:@"WIFI_ONLY"]) {
            self.upload_connection_type = kUploadWifiOnly;
        } else if ([connection_type isEqualToString:@"ANY_CONNECTION"]) {
            self.upload_connection_type = kUploadWhenAnyConnection;
        } else {
            NSLog(@"Invalid connection type: %@", connection_type);
        }
    }

    if (options[@"upload_frequency"] != nil) {
        self.upload_frequency = options[@"upload_frequency"];
    }

    if (options[@"upload_request_format"] != nil) {
        NSString* request_format = options[@"upload_request_format"];
        if ([request_format isEqualToString:@"JSON"]) {
            self.upload_request_format = kUploadRequestFormatJSON;
        } else if ([request_format isEqualToString:@"FORM_URL_ENCODED"]) {
            self.upload_request_format = kUploadRequestFormatFormURLEncoded;
        } else {
            NSLog(@"Invalid request format", request_format);
        }
    }

    if (options[@"upload_locations_param"] != nil) {
        self.upload_locations_param = options[@"upload_locations_param"];
    }

    if (options[@"upload_extra_params"] != nil) {
        self.upload_extra_params = options[@"upload_extra_params"];
    }

    if (options[@"upload_fields"] != nil) {
        self.upload_field_timestamp = NO;
        self.upload_field_latitude  = NO;
        self.upload_field_longitude = NO;
        self.upload_field_accuracy  = NO;
        self.upload_field_heading   = NO;
        self.upload_field_speed     = NO;

        for (NSString* field in options[@"fields"]) {
            if ([field isEqualToString:@"timestamp"]) {
                self.upload_field_timestamp = YES;
            } else if ([field isEqualToString:@"latitude"]) {
                self.upload_field_latitude = YES;
            } else if ([field isEqualToString:@"longitude"]) {
                self.upload_field_longitude = YES;
            } else if ([field isEqualToString:@"accuracy"]) {
                self.upload_field_accuracy = YES;
            } else if ([field isEqualToString:@"heading"]) {
                self.upload_field_heading = YES;
            } else if ([field isEqualToString:@"speed"]) {
                self.upload_field_speed = YES;
            } else {
                NSLog(@"Invalid field", field);
            }
        }
    }

    if (options[@"keep_locations_for"] != nil) {
        int num_days = [options[@"keep_locations_for"] intValue];
        LocationStore* locationStore = [LocationStore sharedStore];
        [locationStore keepLocationsFor:num_days];
    }
}

// ==========================================================================
//
// start
//
//     Start background geolocation.

RCT_REMAP_METHOD(start, start_with_resolver:(RCTPromiseResolveBlock)resolve
                                   rejecter:(RCTPromiseRejectBlock)reject) {

#if DEBUG_MODE
    NSLog(@"In [LocationCapture start]");
#endif

    // Check that we're allowed to access the user's location.

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if ((status == kCLAuthorizationStatusRestricted) ||
        (status == kCLAuthorizationStatusDenied)) {
        // The user refused to let us access their location.
        resolve(@"DENIED");
        return;
    }

    self.background_location_manager = [[CLLocationManager alloc] init];
    self.background_location_manager.delegate = self;

    // If necessary, ask the user for permission to monitor their location.

    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.background_location_manager requestAlwaysAuthorization];
    }

    // Check that location services have been enabled.

    if (![CLLocationManager locationServicesEnabled]) {
        // Location services are not enabled for some reason.
        resolve(@"UNAVAILABLE");
        return;
    }

    CLLocationDistance num_metres;
    if (self.distance_filter == nil) {
        num_metres = kCLDistanceFilterNone;
    } else {
        num_metres = [self.distance_filter intValue];
    }

    self.background_location_manager.desiredAccuracy = kCLLocationAccuracyBest;
    self.background_location_manager.distanceFilter  = num_metres;
    self.background_location_manager.activityType    = CLActivityTypeFitness;
    self.background_location_manager.allowsBackgroundLocationUpdates = YES;
    [self.background_location_manager startUpdatingLocation];

    // Finally, tell the caller the good news.

    resolve(@"OK");
}

// ==========================================================================
//
// stop
//
//     Stop background geolocation.

RCT_REMAP_METHOD(stop, stop_with_resolver:(RCTPromiseResolveBlock)resolve
                                 rejecter:(RCTPromiseRejectBlock)reject) {
#if DEBUG_MODE
    NSLog(@"In [LocationCapture stop]");
#endif

    [self.background_location_manager stopUpdatingLocation];
    self.background_location_manager = nil;

    resolve(@"OK");
}

// ==========================================================================
//
// retrieve
//
//     Retrieve some recorded locations from the internal database.

RCT_REMAP_METHOD(retrieve, anchor:(NSString*)anchor
                            limit:(nonnull NSNumber*)limit
                         resolver:(RCTPromiseResolveBlock)resolve
                         rejecter:(RCTPromiseRejectBlock)reject) {

#if DEBUG_MODE
    NSLog(@"In [LocationCapture retrieve]");
#endif

    LocationStore* locationStore = [LocationStore sharedStore];
    NSDictionary* results = [locationStore retrieveWithAnchor:anchor
                                                        limit:[limit intValue]];

    resolve(results);
}

// ==========================================================================
//
// getLatestAnchor
//
//     Return the latest anchor value to use from the internal database.

RCT_REMAP_METHOD(getLatestAnchor,
                 get_latest_with_resolver:(RCTPromiseResolveBlock)resolve
                                 rejecter:(RCTPromiseRejectBlock)reject) {

#if DEBUG_MODE
    NSLog(@"In [LocationCapture getLatestAnchor]");
#endif

    LocationStore* locationStore = [LocationStore sharedStore];
    NSString* latestAnchor = [locationStore getLatestAnchor];

    resolve(latestAnchor);
}

// ==========================================================================
// ==                                                                      ==
// ==  C L L O C A T I O N M A N A G E R D E L E G A T E   M E T H O D S   ==
// ==                                                                      ==
// ==========================================================================
//
// locationManager:didUpdateLocations:
//
//    Respond to one or more location updates being received by one of our
//    location managers.

- (void) locationManager:(CLLocationManager*)manager
      didUpdateLocations:(NSArray<CLLocation*>*)locations {

    if ((manager == self.cur_location_manager) &&
        (self.cur_location_resolve != nil)) {
        // We requested a one-off location and this is the response.

        CLLocation* loc = locations[0];

        NSNumber* latitude;
        latitude = [NSNumber numberWithDouble:loc.coordinate.latitude];

        NSNumber* longitude;
        longitude = [NSNumber numberWithDouble:loc.coordinate.longitude];

        NSNumber* accuracy;
        accuracy = [NSNumber numberWithInt:(int)loc.horizontalAccuracy];

        NSNumber* heading;
        if (loc.course >= 0) {
            heading = [NSNumber numberWithInt:(int)loc.course];
        } else {
            heading = [NSNumber numberWithInt:-1];
        }

        NSNumber* speed;
        if (loc.speed >= 0) {
            speed = [NSNumber numberWithInt:(int)loc.speed];
        } else {
            speed = [NSNumber numberWithInt:-1];
        }

        NSDictionary* location = @{@"latitude"  : latitude,
                                   @"longitude" : longitude,
                                   @"accuracy"  : accuracy,
                                   @"heading"   : heading,
                                   @"speed"     : speed};

        NSLog(@"Resolving current location: %@", location);
        self.cur_location_resolve(location);
        self.cur_location_resolve = nil;

    } else if (manager == self.background_location_manager) {

        // We received a location while running in the background.

#if DEBUG_MODE
        NSLog(@"In [LocationCapture locationManager:didUpdateLocations:]");
#endif

        // Go through the received locations, filtering out the ones which
        // don't meet our filter requirents and creating a "location"
        // dictionary for each location to be processed.

        NSMutableArray* locations_to_process = [[NSMutableArray alloc] init];

        for (CLLocation* loc in locations) {

            // Respect the time filter, if we have one.

            if (self.time_filter != nil) {
                int num_secs = [self.time_filter intValue];
                if (num_secs > 0) {
                    NSDate* now = [NSDate date];
                    if (self.last_update != nil) {
                        int secs_ago = (int)[now timeIntervalSinceDate:
                                                            self.last_update];
                        if (secs_ago < num_secs) {
                            // We haven't waited long enough -> ignore this
                            // location.
                            continue;
                        }
                    }
                    self.last_update = now;
                }
            }

            // Extract the data we need, and assemble it into a location
            // dictionary.

            NSNumber* timestamp;
            timestamp = [NSNumber numberWithDouble:
                            [loc.timestamp timeIntervalSince1970]];

            NSNumber* latitude;
            latitude = [NSNumber numberWithDouble:loc.coordinate.latitude];

            NSNumber* longitude;
            longitude = [NSNumber numberWithDouble:loc.coordinate.longitude];

            NSNumber* accuracy;
            accuracy = [NSNumber numberWithInt:(int)loc.horizontalAccuracy];

            NSNumber* heading;
            if (loc.course >= 0) {
                heading = [NSNumber numberWithInt:(int)loc.course];
            } else {
                heading = [NSNumber numberWithInt:-1];
            }

            NSNumber* speed;
            if (loc.speed >= 0) {
                speed = [NSNumber numberWithInt:(int)loc.speed];
            } else {
                speed = [NSNumber numberWithInt:-1];
            }

            NSDictionary* location = @{@"timestamp" : timestamp,
                                       @"latitude"  : latitude,
                                       @"longitude" : longitude,
                                       @"accuracy"  : accuracy,
                                       @"heading"   : heading,
                                       @"speed"     : speed};

            [locations_to_process addObject:location];
        }

        // If we don't have any locations, give up.

        if ([locations_to_process count] == 0) {
            return;
        }

        // Now that we have an array of locations to process, pass these
        // locations on to the location store.

#if DEBUG_MODE
        NSLog(@"Received %d GPS locations for processing",
              [locations_to_process count]);
#endif

        LocationStore* locationStore = [LocationStore sharedStore];
        [locationStore add:locations_to_process];

        // If we've been configured to do so, upload the locations to a remote
        // server.  Note that we queue the locations and upload them at the
        // appropriate time.

        if (self.upload_enabled) {
            for (NSDictionary* location in locations_to_process) {
                [self add_to_upload_queue:location];
            }

            if ([self should_upload_to_server]) {
                [self send_upload_queue_to_server];
            }
        }

        // Finally, tell our Javscript code that we've added some locations to the
        // store.

        [self send_notification];
    }
}

// ==========================================================================
//
// locationManager:didFailWithError:
//
//     Respond to the location manager generating an error.
//
//     This is called whenever one of our location managers failed to retrieve a
//     location value.

- (void)locationManager:(CLLocationManager*)manager
       didFailWithError:(NSError*)error {

    if ((manager == self.cur_location_manager) &&
        (self.cur_location_reject != nil)) {

        // Our attempt to get the user's current location failed.

        self.cur_location_reject(@"UNAVAILABLE",
                                 @"Unable to get location",
                                 error);
        self.cur_location_reject = nil;

    } else if (manager == self.background_location_manager) {

        // An error occurred while capturing locations in the background.

        NSLog([NSString stringWithFormat:@"%ld: %@",
                                         error.code,
                                         [error localizedDescription]]);
    }
}

// ==========================================================================
// ==                                                                      ==
// ==            R C T E V E N T E M I T T E R   M E T H O D S             ==
// ==                                                                      ==
// ==========================================================================
//
// supportedEvents
//
//     Return the list of events we can send back to the Javascript code.

- (NSArray<NSString*>*) supportedEvents {

    return @[@"location_received"];
}

// ==========================================================================

@end
