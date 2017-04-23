//  Database.m
//
//  Copyright (c) 2016 Erik Westra.  All rights reserved.
//
// ##########################################################################

#import "Database.h"

#import <Foundation/Foundation.h>
#import <sqlite3.h>

// ##########################################################################
//
// The name of our database file:

static NSString* DATABASE_NAME = @"database.sqlite";

// ##########################################################################
//
// Private globals that hold the state of our static Database class:

static bool                _logDBQueries = NO;  // Log DB queries?
static NSLock*             _lock         = nil; // Our database lock.
static DatabaseConnection* _connection   = nil; // Our shared db connection.

// ##########################################################################
//
// Private DatabaseConnection definitions:

@interface DatabaseConnection ()

@property (nonatomic) sqlite3* conn;

// ==========================================================================
//
// initWithConnection:
//
//     Initialise a new DatabaseConnection object with the given sqlite3
//     connection.

- (id) initWithConnection:(sqlite3*)connection;

// ==========================================================================
//
// close
//
//     Close this DatabaseConnection object.

- (void) close;

// ==========================================================================
//
// logErrorForCmd:
//
//     Log the error that occurrred while executing the given command.

- (void) logErrorForCmd:(NSString*)cmd;

// ==========================================================================
//
// valueToString:
//
//     Convenience method to convert a value to a string.  If the value is
//     itself a string, the string is quoted.

- (NSString*) valueToString:(NSObject*)value;

// ==========================================================================
//
// getQuotedValuesFrom:forFields:
//
//     Convenience method to extract (and where necessary wrap in single
//     quotes) a given set of field values from a dictionary.
//
//     'record' should be an NSDictionary holding the values the user has
//     requested, and 'fields' should be an NSArray of field values to extract.
//
//     We create and return an NSArray holding the field values, converted to a
//     string with single quote marks around them where necessary.

- (NSArray*) getQuotedValuesFrom:(NSDictionary*)record
                       forFields:(NSArray*)fields;

// ==========================================================================
//
// string:withParams:
//
//     Replace placeholders in a format string with the given parameter values.
//
//     'string' should be a format string with "%@" placeholders for the
//     parameters, and 'params' should be an array of parameters.
//
//     We return the given string with the placeholders replaced by the given
//     parameter values.

- (NSString*) string:(NSString*)string withParams:(NSArray*)params;

// ==========================================================================
//
// normaliseSchema:
//
//     Normalise the given schema definition string for comparison purposes.
//
//     We return the given string with all leading and trailing whitespace
//     characters removed, any repeated occurrences of whitespace within the
//     string replaced with a single space, and the resulting string converted
//     to uppercase.  This can be used to compare two schema definitions to see
//     if they are the same.

- (NSString*) normaliseSchema:(NSString*)schema;

// ==========================================================================

@end

// ##########################################################################

@implementation Database

// ==========================================================================

+ (DatabaseConnection*) getConnection {

    if (_lock == nil) {
        _lock = [[NSLock alloc] init];
    }

    // TESTING:

    //NSLog(@"Acquiring database lock, call stack: %@",
    //      [NSThread callStackSymbols]);

    // END OF TESTING.

    [_lock lock];

    if (_connection != nil) {
        return _connection;
    }

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString* documentDir = [paths objectAtIndex:0];
    NSString* dbPath = [documentDir stringByAppendingPathComponent:DATABASE_NAME];

    sqlite3* connection;
    int result = sqlite3_open([dbPath UTF8String], &connection);
    if (result != SQLITE_OK) {
        NSLog(@"[SQLITE] Unable to open database, code = %d!", result);
        return nil;
    }

    _connection = [[DatabaseConnection alloc] initWithConnection:connection];
    return _connection;
}

// ==========================================================================

+ (void) releaseConnection:(DatabaseConnection*)connection {

    // TESTING:

    //NSLog(@"Releasing database lock, call stack: %@",
    //      [NSThread callStackSymbols]);

    // END OF TESTING.

    [_lock unlock];
}

// ==========================================================================

+ (void) logQueries:(BOOL)logQueries {

    _logDBQueries = logQueries;
}

// ==========================================================================

@end

// ##########################################################################

@implementation DatabaseConnection

// ==========================================================================
//                                                                         ==
//         T R A N S A C T I O N - H A N D L I N G   M E T H O D S         ==
//                                                                         ==
// ==========================================================================

- (void) beginTransaction {

    [self execute:@"BEGIN EXCLUSIVE TRANSACTION"];
}

// ==========================================================================

- (void) commitTransaction {

    [self execute:@"COMMIT TRANSACTION"];
}

// ==========================================================================

- (void) rollbackTransaction {

    [self execute:@"ROLLBACK TRANSACTION"];
}

// ==========================================================================
//                                                                         ==
//           C O M M A N D   A N D   Q U E R Y   M E T H O D S             ==
//                                                                         ==
// ==========================================================================

- (void) execute:(NSString*)command {

    if (_logDBQueries) {
        NSLog(@"[SQLITE] %@", command);
    }

    sqlite3_stmt* statement = nil;
    const char*   sql       = [command UTF8String];
    
    if (sqlite3_prepare_v2(self.conn, sql, -1, &statement, NULL) != SQLITE_OK) {
        [self logErrorForCmd:command];
    } else {
        int result = sqlite3_step(statement);
        if (result == SQLITE_ERROR) {
            [self logErrorForCmd:command];
        }
    }

    sqlite3_finalize(statement);
}

// ==========================================================================

- (void) execute:(NSString*)command with:(NSArray*)params {

    command = [self string:command withParams:params];
    [self execute:command];
}

// ==========================================================================

- (NSArray*) query:(NSString*)query {

    if (_logDBQueries) {
        NSLog(@"[SQLITE] %@", query);
    }

    sqlite3_stmt* statement = nil;
    const char*   sql       = [query UTF8String];

    if (sqlite3_prepare_v2(self.conn, sql, -1, &statement, NULL) != SQLITE_OK) {
        [self logErrorForCmd:query];
        return nil;
    } else {
        NSMutableArray* results = [NSMutableArray array];

        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableArray* row = [NSMutableArray array];

            for (int i=0; i < sqlite3_column_count(statement); i++) {
                int colType = sqlite3_column_type(statement, i);
                id value;
                if (colType == SQLITE_TEXT) {
                    const unsigned char* col = sqlite3_column_text(statement, i);
                    value = [NSString stringWithFormat:@"%s", col];
                } else if (colType == SQLITE_INTEGER) {
                    int col = sqlite3_column_int(statement, i);
                    value = [NSNumber numberWithInt:col];
                } else if (colType == SQLITE_FLOAT) {
                    double col = sqlite3_column_double(statement, i);
                    value = [NSNumber numberWithDouble:col];
                } else if (colType == SQLITE_NULL) {
                    value = [NSNull null];
                } else {
                    NSLog(@"[SQLITE] Unsupported datatype: %d", colType);
                }

                [row addObject:value];
            }

            [results addObject:row];
        }

        sqlite3_finalize(statement);

        return results;
    }
}

// ==========================================================================

- (NSArray*) query:(NSString*)query with:(NSArray*)params {

    query = [self string:query withParams:params];
    return [self query:query];
}

// ==========================================================================
//                                                                         ==
//                C O N V E N I E N C E   M E T H O D S                    ==
//                                                                         ==
// ==========================================================================

- (NSInteger) insertRecord:(NSDictionary*)record
                 intoTable:(NSString*)tableName {

    NSArray* fields = [record allKeys];
    NSArray* values = [self getQuotedValuesFrom:record forFields:fields];

    NSMutableString* sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"INSERT INTO %@", tableName];
    [sql appendString:@" ("];
    [sql appendString:[fields componentsJoinedByString:@","]];
    [sql appendString:@" ) VALUES ("];
    [sql appendString:[values componentsJoinedByString:@","]];
    [sql appendString:@")"];

    [self execute:sql];

    return sqlite3_last_insert_rowid(self.conn);
}

// ==========================================================================

- (void) updateRecord:(NSDictionary*)record
               withID:(NSInteger)recordID
              inTable:(NSString*)tableName {

    NSArray* fields = [record allKeys];
    NSArray* values = [self getQuotedValuesFrom:record forFields:fields];

    NSMutableString* sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"UPDATE %@", tableName];
    [sql appendString:@" SET "];

    NSMutableArray* fieldSets = [[NSMutableArray alloc] init];

    for (int i = 0; i < [fields count]; i++) {
        NSString* field = fields[i];
        NSString* value = values[i];

        [fieldSets addObject: [NSString stringWithFormat:@"%@=%@",
                               field, value]];
    }

    [sql appendString:[fieldSets componentsJoinedByString:@","]];
    [sql appendFormat:@" WHERE id=%ld", (long)recordID];

    [self execute:sql];
}

// ==========================================================================

- (void) deleteRecordWithID:(NSInteger)recordID
                    inTable:(NSString*)tableName {


    NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id=%ld",
                                               tableName, (long)recordID];
    [self execute:sql];
}

// ==========================================================================

- (BOOL) tableExists:(NSString*)tableName {

    NSArray* results = [self query:@"SELECT name FROM sqlite_master "
                                   @"WHERE type='table' AND tbl_name='%@'"
                              with:@[tableName]];
    if ([results count] == 0) {
        return NO;
    } else {
        return YES;
    }
}

// ===========================================================================
// ==                                                                       ==
// ==            S C H E M A   C H E C K I N G   M E T H O D S              ==
// ==                                                                       ==
// ===========================================================================
//
// ensureSchemaForTable:is:
//
//     Ensure that the given database table has the given schema.
//
//     "schema" should be a string containing an SQL "CREATE TABLE" command
//     that creates the given database table.  We check the existing schema for
//     the given table; if the schema matches, we do nothing.  Otherwise, the
//     existing table is dropped (if it exists) and the table is recreated
//     using the given schema definition.

- (void) ensureSchemaForTable:(NSString*)table
                           is:(NSString*)schema {

    BOOL rebuild_table = NO; // initially.

    NSArray* results = [self query:@"SELECT sql FROM sqlite_master "
                                   @"WHERE type='table' "
                                   @"AND name='%@'"
                              with:[NSArray arrayWithObject:table]];
    if ([results count] == 0) {
        rebuild_table = YES;
    } else {
        NSString* existing_schema = [self normaliseSchema:results[0][0]];
        NSString* new_schema      = [self normaliseSchema:schema];
        if (![existing_schema isEqualToString:new_schema]) {
            rebuild_table = YES;
        }
    }

    if (rebuild_table) {
        [self beginTransaction];
        [self execute:@"DROP TABLE IF EXISTS %@"
                 with:[NSArray arrayWithObject:table]];
        [self execute:schema];
        [self commitTransaction];
    }
}

// ===========================================================================
//
// ensureSchemaForIndex:is:
//
//     Ensure that the given database index has the given schema.
//
//     "schema" should be a string containing an SQL "CREATE INDEX" command
//     that creates the given database index.  We check the existing schema for
//     the given index; if the schema matches, we do nothing.  Otherwise, the
//     existing index is dropped (if it exists) and the index is recreated
//     using the given schema definition.

- (void) ensureSchemaForIndex:(NSString*)index
                           is:(NSString*)schema {

    BOOL rebuild_index = NO; // initially.

    NSArray* results = [self query:@"SELECT sql FROM sqlite_master "
                                   @"WHERE type='index' "
                                   @"AND name='%@'"
                              with:[NSArray arrayWithObject:index]];
    if ([results count] == 0) {
        rebuild_index = YES;
    } else {
        NSString* existing_schema = [self normaliseSchema:results[0][0]];
        NSString* new_schema      = [self normaliseSchema:schema];
        if (![existing_schema isEqualToString:new_schema]) {
            rebuild_index = YES;
        }
    }

    if (rebuild_index) {
        [self beginTransaction];
        [self execute:@"DROP INDEX IF EXISTS %@"
                 with:[NSArray arrayWithObject:index]];
        [self execute:schema];
        [self commitTransaction];
    }
}

// ==========================================================================
// ==                                                                      ==
// ==                    P R I V A T E   M E T H O D S                     ==
// ==                                                                      ==
// ==========================================================================
//
// initWithConnection:
//
//     Initialise a new DatabaseConnection object with the given sqlite3
//     connection.

- (id) initWithConnection:(sqlite3*)connection {

    if (self = [super init]) {
        self.conn = connection;
    }
    return self;
}

// ==========================================================================
//
// close
//
//     Close this DatabaseConnection object.

- (void) close {

    sqlite3_close(self.conn);
}

// ==========================================================================

- (void) logErrorForCmd:(NSString*)cmd {

    NSString* errMsg = [[NSString alloc]
                            initWithCString:sqlite3_errmsg(self.conn)
                                   encoding:NSASCIIStringEncoding];

    NSLog(@"[SQLITE] %@", cmd);
    NSLog(@"[SQLITE]   %@", errMsg);
}

// ==========================================================================

- (NSString*) valueToString:(NSObject*)value {

    NSString* sValue;
    if ([value isKindOfClass:[NSNull class]]) {
        sValue = @"NULL";
    } else if ([value isKindOfClass:[NSString class]]) {
        sValue = (NSString*)value;
        sValue = [sValue stringByReplacingOccurrencesOfString:@"'"
                                                   withString:@"''"];
        sValue = [NSString stringWithFormat:@"'%@'", sValue];
    } else {
        sValue = [NSString stringWithFormat:@"%@", value];
    }
    return sValue;
}

// ==========================================================================

- (NSArray*) getQuotedValuesFrom:(NSDictionary*)record
                       forFields:(NSArray*)fields {

    NSMutableArray* quotedValues = [[NSMutableArray alloc] init];
    for (NSString* field in fields) {
        NSObject* value = [record objectForKey:field];
        NSString* sValue = [self valueToString:value];
        [quotedValues addObject:sValue];
    }

    return quotedValues;
}

// ==========================================================================

- (NSString*) string:(NSString*)string withParams:(NSArray*)params {

    NSMutableString* s = [[NSMutableString alloc] init];
    [s setString:string];

    for (int i=0; i < [params count]; i++) {
        NSString* sValue = [NSString stringWithFormat:@"%@", params[i]];
        NSRange range = [s rangeOfString:@"%@"];
        if (range.location == NSNotFound) {
            NSLog(@"FATAL ERROR: Unable to add value to format string");
            NSLog(@"string = %@", s);
            break;
        } else {
            [s replaceCharactersInRange:range withString:sValue];
        }
    }

    return s;
}

// ==========================================================================

- (NSString*) normaliseSchema:(NSString*)schema {

    NSCharacterSet* whitespace     = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate*    noEmptyStrings = [NSPredicate
                                        predicateWithFormat:@"SELF != ''"];

    NSArray* parts = [schema componentsSeparatedByCharactersInSet:whitespace];
    NSArray* filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
    NSString* result = [filteredArray componentsJoinedByString:@" "];

    return result.uppercaseString;
}

// ==========================================================================

@end
