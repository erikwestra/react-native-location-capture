// UploadQueue.m
//
// Implementation for the UploadQueue class.
//
// ##########################################################################

#import "UploadQueue.h"
#import "Database.h"

// ##########################################################################
//
// Should we write debugging messages to the console?

#define DEBUG_MODE 1

// ##########################################################################
//
// Our database schema:

static NSString* TABLE_SCHEMA = @"CREATE TABLE upload_queue("
                                @"  id        INTEGER PRIMARY KEY,"
                                @"  timestamp TEXT,"
                                @"  latitude  DOUBLE,"
                                @"  longitude DOUBLE,"
                                @"  accuracy  INTEGER,"
                                @"  heading   INTEGER,"
                                @"  speed     INTEGER)";

static NSString* INDEX_SCHEMA = @"CREATE INDEX upload_queue_index "
                                @"ON upload_queue(timestamp)";

// ##########################################################################
//
// Private class definitions:

@interface UploadQueue ()

@property (strong, nonatomic) NSLock* _lock;

// ==========================================================================
//
// init
//
//     Initialise the singleton upload queue object.
//
//     Note that we create our database table.  If the existing schema does not
//     match, we delete the old table and start again.

- (id) init;

// ==========================================================================

@end

// ##########################################################################

@implementation UploadQueue

@synthesize _lock;

// ==========================================================================
// ==                                                                      ==
// ==                    P R I V A T E   M E T H O D S                     ==
// ==                                                                      ==
// ==========================================================================

- (UploadQueue*) init {

    if (self = [super init]) {
        self._lock = [[NSLock alloc] init];

        DatabaseConnection* conn = [Database getConnection];

        [conn ensureSchemaForTable:@"upload_queue"
                                is:TABLE_SCHEMA];
        [conn ensureSchemaForIndex:@"upload_queue_index"
                                is:INDEX_SCHEMA];

        [Database releaseConnection:conn];
    }
    return self;
}

// ==========================================================================
// ==                                                                      ==
// ==                     P U B L I C   M E T H O D S                      ==
// ==                                                                      ==
// ==========================================================================

+ (id) sharedQueue {

    static UploadQueue* _sharedQueue = nil;
    @synchronized(self) {
        if (_sharedQueue == nil)
            _sharedQueue = [[self alloc] init];
    }
    return _sharedQueue;
}

// ==========================================================================

- (void) add:(NSDictionary*)location {

    [self._lock lock];

    NSDictionary* loc = @{@"timestamp" : location[@"timestamp"],
                          @"latitude"  : location[@"latitude"],
                          @"longitude" : location[@"longitude"],
                          @"accuracy"  : location[@"accuracy"],
                          @"heading"   : location[@"heading"],
                          @"speed"     : location[@"speed"]};

#if DEBUG_MODE
    NSLog(@"In [UploadQueue add], loc = %@", loc);
#endif

    DatabaseConnection* conn = [Database getConnection];
    [conn beginTransaction];
    [conn insertRecord:loc intoTable:@"upload_queue"];
    [conn commitTransaction];
    [Database releaseConnection:conn];

    [self._lock unlock];
}

// ==========================================================================

- (NSArray*) flush {

    [self._lock lock];

    DatabaseConnection* conn = [Database getConnection];
    [conn beginTransaction];

    NSArray* results = [conn query:@"SELECT timestamp, latitude, longitude,"
                                   @" accuracy, heading, speed "
                                   @"FROM upload_queue "
                                   @"ORDER BY timestamp"];
    [conn execute:@"DELETE FROM upload_queue"];

    [conn commitTransaction];
    [Database releaseConnection:conn];
    [self._lock unlock];

    NSMutableArray* locations = [[NSMutableArray alloc] init];
    for (int i=0; i < [results count]; i++) {
        NSArray* row = results[i];
        [locations addObject:@{@"timestamp" : row[0],
                               @"latitude"  : row[1],
                               @"longitude" : row[2],
                               @"accuracy"  : row[3],
                               @"heading"   : row[4],
                               @"speed"     : row[5]}];
    }

#if DEBUG_MODE
    NSLog(@"In [UploadQueue flush], locations = %@", locations);
#endif

    return locations;
}

// ==========================================================================

- (void) restore:(NSArray*)locations {

    [self._lock lock];

#if DEBUG_MODE
    NSLog(@"In [UploadQueue restore], locations = %@", locations);
#endif

    DatabaseConnection* conn = [Database getConnection];
    [conn beginTransaction];

    for (NSDictionary* loc in locations) {
        [conn insertRecord:loc intoTable:@"upload_queue"];
    }

    [conn commitTransaction];
    [Database releaseConnection:conn];
    [self._lock unlock];
}

// ==========================================================================

@end

