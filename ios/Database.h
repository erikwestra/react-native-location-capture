//  Database.h
//
//  This module implements a simple Database class built on top of SQlite.
//
//  Copyright (c) 2016 Erik Westra.  All rights reserved.
//
// ##########################################################################

#import <Foundation/Foundation.h>

@class DatabaseConnection;

// ##########################################################################
//
// Database
//
//     A thin wrapper around SQLite, providing a shared DatabaseConnection
//     objects as required.
//
//     Note that this is a static class; all methods are static methods and you
//     should never instantiate a Database object.

@interface Database : NSObject

// ==========================================================================
//
// getConnection
//
//     Return a reference to our shared database connection.  Note that only
//     one caller can get access to the shared connection at a time; you must
//     call the [Database releaseConnection:] method to release the connection
//     so that another caller can retrieve it.
//
//     This function blocks until the connection is available.

+ (DatabaseConnection*) getConnection;

// ==========================================================================
//
// releaseConnection:
//
//     Release a previously-allocated database connection.
//
//     This must be called as soon as the connection is no longer needed.

+ (void) releaseConnection:(DatabaseConnection*)connection;

// ==========================================================================
//
// logQueries:
//
//     Turn on or off datbase query logging.
//
//     If 'logQueries' is set to YES, all database queries will be written to
//     the console.

+ (void) logQueries:(BOOL)logQueries;

// ==========================================================================

@end

// ##########################################################################
//
// DatabaseConnection
//
//     An object representing a connection to the database.
//
//     The following data types are supported:
//
//         * TEXT fields are returned as NSString objects.
//
//         * INTEGER fields are returned as NSNumber objects holding an int
//           value.
//
//         * FLOAT fields are returned as NSNumber objects holding a double
//           value.
//
//         * Null values are returned as NSNull objects.
//
//     You should never instantiate a DatabaseConnection object directly.
//     instead, call [Database getConnection] to get a new database connection,
//     and then call [Database releaseConnection:connection] to release the
//     connection when you are finished with it.

@interface DatabaseConnection : NSObject

// ==========================================================================
//                                                                         ==
//          T R A N S A C T I O N - H A N D L I N G   M E T H O D S        ==
//                                                                         ==
// ==========================================================================
//
// beginTransaction
//
//      Start a database transaction.
//
//      Note that database transactions cannot be nested.

- (void) beginTransaction;

// ==========================================================================
//
// commitTransaction
//
//     End the current database transaction, commiting any changes which have
//     been made.

- (void) commitTransaction;

// ==========================================================================
//
// rollbackTransaction
//
//     End the current database transaction, rolling back any changes which have
//     been made.

- (void) rollbackTransaction;

// ==========================================================================
//                                                                         ==
//           C O M M A N D   A N D   Q U E R Y   M E T H O D S             ==
//                                                                         ==
// ==========================================================================
//
// execute:
//
//     Perform the given SQL command, discarding the result.

- (void) execute:(NSString*)command;

// ==========================================================================
//
// execute:with:
//
//      Perform the given SQL command with query parameters, discarding the
//      result.
//
//      This version of [Database execute:] accepts an array of query
//      parameters.  These query parameters are used to replace the "%@"
//      placeholders in the command string.

- (void) execute:(NSString*)command with:(NSArray*)params;

// ==========================================================================
//
// query:
//
//     Perform the given SQL query, returning an array of results.
//
//     The returned array will have one entry for each row returned by the
//     database.  Each row will itself be an NSArray object containing the
//     values for that row.

- (NSArray*) query:(NSString*)query;

// ==========================================================================
//
// query:with:
//
//     Perform the given SQL query with query parameters, returning an array of
//     results.
//
//      This version of [Database query:] accepts an array of query parameters.
//      These query parameters are used to replace the "%@" placeholders in the
//      query string.

- (NSArray*) query:(NSString*)query with:(NSArray*)params;

// ==========================================================================
//                                                                         ==
//                C O N V E N I E N C E   M E T H O D S                    ==
//                                                                         ==
// ==========================================================================
//
// insertRecord:intoTable:
//
//     Create a new record with the contents of the given dictionary in the
//     given database table.
//
//     We return the record ID of the newly-inserted record.
//
//     Note that the table must have an integer primary key field named "id"
//     for this method to work.

- (NSInteger) insertRecord:(NSDictionary*)record
                 intoTable:(NSString*)tableName;

// ==========================================================================
//
// updateRecord:withID:inTable:
//
//     Update a record with the given ID value in the given table.
//
//     'record' should be a dictionary mapping field names to values for the
//     values to update in the record.
//
//     Note that the table must have an integer primary key field named "id"
//     for this method to work.

- (void) updateRecord:(NSDictionary*)record
               withID:(NSInteger)recordID
              inTable:(NSString*)tableName;

// ==========================================================================
//
// deleteRecordWithID:inTable:
//
//     Delete a record with the given ID value in the given table.
//
//     Note that the table must have an integer primary key field named "id"
//     for this method to work.

- (void) deleteRecordWithID:(NSInteger)recordID
                    inTable:(NSString*)tableName;

// ==========================================================================
//
// tableExists:
//
//     Return YES if the given table exists in the database, else return NO.

- (BOOL) tableExists:(NSString*)tableName;

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
                           is:(NSString*)schema;

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
                           is:(NSString*)schema;

// =============================================================================

@end

