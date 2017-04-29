// LocationStore.m
//
// Implementation for the LocationStore class.

#import "LocationStore.h"
#import "Database.h"

// ##########################################################################
//
// Should we write debugging messages to the console?

#define DEBUG_MODE 0

// ##########################################################################
//
// Our database schema:

static NSString* LOCATION_TABLE_SCHEMA =
    @"CREATE TABLE location_store_location("
    @"  id        INTEGER PRIMARY KEY,"
    @"  timestamp INTEGER,"
    @"  latitude  DOUBLE,"
    @"  longitude DOUBLE,"
    @"  accuracy  INTEGER,"
    @"  heading   DOUBLE,"
    @"  speed     DOUBLE)";

static NSString* LOCATION_INDEX_SCHEMA =
    @"CREATE INDEX location_store_location_index "
    @"ON location_store_location(timestamp)";

// ##########################################################################
//
// Our private interface:

@interface LocationStore ()

@property (strong, nonatomic) NSLock*   _lock;
@property (atomic, strong)    NSNumber* _num_days;

// ==========================================================================
//
// init
//
//     Initialise our singleton location store object.
//
//     Note that we create our database table.  If the existing schema does not
//     match, we delete the old tables and start again.

- (id) init;

// ==========================================================================
//
// delete_old_locations
//
//     Delete any locations in the database more than '_num_days' days old.
//
//     Note that the lock is not acquired by this method; the calling method
//     should have already acquired the lock before calling this method.

- (void) delete_old_locations;

// ==========================================================================

@end

// ##########################################################################

@implementation LocationStore

// ==========================================================================
// ==                                                                      ==
// ==                    P R I V A T E   M E T H O D S                     ==
// ==                                                                      ==
// ==========================================================================

- (id) init {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore init]");
#endif

    if (self = [super init]) {
        self._lock     = [[NSLock alloc] init];
        self._num_days = nil;

        DatabaseConnection* conn = [Database getConnection];

        [conn ensureSchemaForTable:@"location_store_location"
                                is:LOCATION_TABLE_SCHEMA];
        [conn ensureSchemaForIndex:@"location_store_location_index"
                                is:LOCATION_INDEX_SCHEMA];

        [Database releaseConnection:conn];
    }

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore init]");
#endif

    return self;
}

// ==========================================================================

- (void) delete_old_locations {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore delete_old_locations]");
#endif

    if ([self._num_days intValue] != -1) {
        DatabaseConnection* conn = [Database getConnection];
        [conn beginTransaction];

        NSCalendar* calendar = [NSCalendar currentCalendar];

        int days = [self._num_days intValue];
        NSDate* cutoff_date = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                   value:-days
                                                  toDate:[NSDate date]
                                                 options:0];
        int cutoff_timestamp = (int)[cutoff_date timeIntervalSince1970];

        [conn execute:@"DELETE FROM location_store_location "
                      @"WHERE timestamp < %@"
                 with:@[[NSNumber numberWithInt:cutoff_timestamp]]];

        [conn commitTransaction];
        [Database releaseConnection:conn];
    }

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore delete_old_locations]");
#endif
}

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================

+ (LocationStore*) sharedStore {

    static LocationStore* _sharedStore = nil;
    @synchronized(self) {
        if (_sharedStore == nil)
            _sharedStore = [[self alloc] init];
    }
    return _sharedStore;
}

// ==========================================================================

- (void) keepLocationsFor:(int)num_days {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore keep_locations_for]");
#endif

    [self._lock lock];

    self._num_days = [NSNumber numberWithInt:num_days];
    [self delete_old_locations];

    [self._lock unlock];

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore keep_locations_for]");
#endif
}

// ==========================================================================

- (void) add:(NSArray*)locations {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore add:]");
#endif

    [self._lock lock];

    DatabaseConnection* conn = [Database getConnection];
    [conn beginTransaction];

    for (NSDictionary* location in locations) {
        [conn insertRecord:location
                 intoTable:@"location_store_location"];
    }

    [conn commitTransaction];
    [Database releaseConnection:conn];

    [self delete_old_locations];

    [self._lock unlock];

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore add:]");
#endif

}

// ==========================================================================

- (NSDictionary*) retrieveWithAnchor:(NSString*)anchor limit:(int)limit {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore retrieveWithAnchor:limit:]");
#endif

    [self._lock lock];
    [self delete_old_locations];

    DatabaseConnection* conn = [Database getConnection];

    // Convert the encoded anchor (if any) into a record ID value.

    NSNumber* rec_id = nil; // initially.
    if ((anchor != nil) && (![anchor isEqualToString:@""])) {
        NSData* rec_id_data = [[NSData alloc] initWithBase64EncodedString:anchor
                                                                  options:0];
        NSString* rec_id_str = [[NSString alloc]
                                initWithData:rec_id_data
                                    encoding:NSUTF8StringEncoding];
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        rec_id = [formatter numberFromString:rec_id_str];
    }

    // Build our search query.

    NSMutableString* query = [[NSMutableString alloc] init];
    [query appendString:@"SELECT id,timestamp,latitude,longitude,accuracy,"];
    [query appendString:@"heading,speed FROM location_store_location"];

    if (rec_id != nil) {
        [query appendString:@" WHERE id > "];
        [query appendString:[rec_id stringValue]];
    }

    [query appendString:@" ORDER BY id"];

    if (limit != -1) {
        [query appendString:[NSString stringWithFormat:@" LIMIT %d", limit]];
    }

    // Retrieve the matching locations from the location store.  At the same
    // time, remember the record ID of the last retrieved location.

    NSNumber*       max_rec_id = nil; // initially.
    NSMutableArray* locations  = [[NSMutableArray alloc] init];

    NSArray* results = [conn query:query];
    for (NSArray* row in results) {
        max_rec_id = row[0];
        [locations addObject:@{@"timestamp" : row[1],
                               @"latitude"  : row[2],
                               @"longitude" : row[3],
                               @"accuracy"  : row[4],
                               @"heading"   : row[5],
                               @"speed"     : row[6]}];
    }

    // Calculate the next anchor value to use.

    NSString* next_anchor;
    if (max_rec_id != nil) {
        NSString* max_id_str    = [max_rec_id stringValue];
        NSData*   max_id_data   = [max_id_str
                                    dataUsingEncoding:NSUTF8StringEncoding];
        next_anchor = [max_id_data base64EncodedStringWithOptions:0];
    } else {
        next_anchor = @"";
    }

    [Database releaseConnection:conn];

    [self._lock unlock];

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore retrieveWithAnchor:limit:]");
#endif

    return @{@"locations"   : locations,
             @"next_anchor" : next_anchor};
}

// ==========================================================================

- (NSString*) getLatestAnchor {

#if DEBUG_MODE
    NSLog(@"Entering [LocationStore getLatestAnchor]");
#endif

    [self._lock lock];

    DatabaseConnection* conn = [Database getConnection];

    NSNumber* max_rec_id = nil; // initially.
    for (NSArray* row in [conn query:@"SELECT max(id) "
                                     @"FROM location_store_location"]) {
        max_rec_id = row[0];
    }

    NSString* latest_anchor;
    if ((max_rec_id != nil) && (max_rec_id != [NSNull null])) {
        NSString* max_id_str    = [max_rec_id stringValue];
        NSData*   max_id_data   = [max_id_str
                                    dataUsingEncoding:NSUTF8StringEncoding];
        latest_anchor = [max_id_data base64EncodedStringWithOptions:0];
    } else {
        latest_anchor = @"";
    }

    [Database releaseConnection:conn];

    [self._lock unlock];

#if DEBUG_MODE
    NSLog(@"Leaving [LocationStore getLatestAnchor]");
#endif

    return latest_anchor;
}

// ==========================================================================

@end
