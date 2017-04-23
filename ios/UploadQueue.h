// UploadQueue.h
//
// This file defines the public interface for the UploadQueue class.
// UploadQueue implements a queue of locations waiting to be uploaded to a
// remote server.  The queued locations are stored in our SQLite database.
//
// Note that the UploadQueue is a singleton class; use the class method
// [UploadQueue sharedQueue] to obtain a reference to the queue.

#import <Foundation/Foundation.h>

// ==========================================================================

@interface UploadQueue : NSObject

// ==========================================================================
//
// sharedQueue
//
//     Return a reference to our singleton upload queue object.

+ (UploadQueue*) sharedQueue;

// ==========================================================================
//
// add:
//
//     Add a location to the queue.
//
//     The 'location' parameter should be an NSDictionary object with the
//     following entries:
//
//          timestamp
//
//              The date and time at which this location was received, as an
//              RFC-3339 formatted string.
//
//         'latitude'
//
//             An NSNumber object holding the latitude value for this location
//             update, as a floating-point value.
//
//         'longitude'
//
//             An NSNumber object holding the longitude value for this location
//             update, as a floating-point value.
//
//         'accuracy'
//
//             An NSNumber holding the accuracy of the received location, in
//             metres.
//
//         'heading'
//
//             An NSNumber object holding the direction the user is currently
//             heading in, measured in degrees clockwise from due north.  This
//             should be set to -1 if the heading cannot be calculated.
//
//         'speed'
//
//             An NSNumber object holding the user's current speed, in metres
//             per second.  This should be set to -1 if the speed cannot be
//             calculated.

- (void) add:(NSDictionary*)location;

// ==========================================================================
//
// flush
//
//     Retrieve and return all the currently-queued locations.
//
//     Returns an NSArray of queued locations, where each location will be an
//     NSDictionary object with the following fields:
//
//         'timestamp'
//
//             An NSString object holding the date and time at which the
//             location update was received by the background geolocator,
//             as an RFC-3339 format string.
//
//         'latitude'
//
//             An NSNumber object holding the latitude value for this location
//             update, as a floating-point value.
//
//         'longitude'
//
//             An NSNumber object holding the longitude value for this location
//             update, as a floating-point value.
//
//         'accuracy'
//
//             An NSNumber holding he accuracy of the received location, in
//             metres.
//
//         'heading'
//
//             An NSNumber object holding the direction the user is currently
//             heading in, measured in degrees clockwise from due north.  This
//             will be set to -1 if the heading cannot be calculated.
//
//         'speed'
//
//             An NSNumber object holding the user's current speed, in metres
//             per second.  This will be set to -1 if the speed cannot be
//             calculated.

- (NSArray*) flush;

// ==========================================================================
//
// restore:
//
//     Restore the given locations back into the upload queue.
//
//     'locations' should be an NSArray of locations which were previously
//     flushed from the queue.
//
//     The given locations will be re-inserted into the upload queue.

- (void) restore:(NSArray*)locations;

// ==========================================================================

@end

