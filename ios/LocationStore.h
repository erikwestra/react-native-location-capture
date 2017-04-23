// LocationStore.h
//
// This file defines the public interface for the LocationStore class.
// LocationStore implements a database table used to store locations that have
// been received by the background geolocator.
//
// Note that the LocationStore is a singleton class; use the class method
// [LocationStore sharedStore] to obtain a reference to the location store.

#import <Foundation/Foundation.h>

// ==========================================================================

@interface LocationStore : NSObject

// ==========================================================================
//
// sharedStore
//
//     Return a reference to our singleton location store object.

+ (LocationStore*) sharedStore;

// ==========================================================================
//
// keepLocationsFor:
//
//     Set the number of days to store location data for.  If 'num_days' is set
//     to -1, the location data will be stored indefinitely.

- (void) keepLocationsFor:(int)num_days;

// ==========================================================================
//
// add:
//
//     Add one or more locations to the location store.
//
//     'locations' should be an array of locations, where each array entry is
//     an NSDictionary object with at least the following fields:
//
//         'timestamp'
//
//             An NSNumber object holding the date and time at which this
//             location was recieved, measured as an integer number of seconds
//             since the 1st of January, 1970, in the device's time zone.
//
//         'latitude'
//
//             An NSNumber object holding the latitude for this location, as a
//             floating-point number.
//
//         'longitude'
//
//             An NSNumber object holding the longitude for this location, as a
//             floating-point number.
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

- (void) add:(NSArray*)locations;

// ==========================================================================
//
// retrieveWithAnchor:limit:
//
//     Retrieve one or more locations from the location store.
//
//     The parameters are as follows:
//
//         'anchor'
//
//             A string identifying the last point at which we retrieved
//             locations from the store.  This is used to ensure we only
//             retrieve locations we haven't seen before.  Use a value of nil
//             to retrieve the first (or oldest) locations in the store.
//
//         'limit'
//
//             The maximum number of locations to retrieve at any one time.
//             Set this to -1 to retrieve all the remaining locations.
//
//     We return an NSDictionary object with the following entries:
//
//         'locations'
//
//             An NSArray containing up to 'limit' locations which have been
//             received since the given 'anchor' point.
//
//         'next_anchor'
//
//             The 'anchor' value to use the next time this method is called to
//             retrieve the next consecutive chunk of locations.
//
//     Each entry in the 'locations' array will be an NSDictionary object with
//     the following fields:
//
//         'timestamp'
//
//             An NSNumber object holding the date and time at which this
//             location was recieved, measured as an integer number of seconds
//             since the 1st of January, 1970, in the device's time zone.
//
//         'latitude'
//
//             An NSNumber object holding the latitude for this location, as a
//             floating-point number.
//
//         'longitude'
//
//             An NSNumber object holding the longitude for this location, as a
//             floating-point number.
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
//
//     Note that this array will be empty if no new locations have been
//     received since the given 'anchor' value.

- (NSDictionary*) retrieveWithAnchor:(NSString*)anchor limit:(int)limit;

// ==========================================================================
//
// getLatestAnchor
//
//     Retrieve the latest anchor value to use.
//
//     This returns the anchor value to use for a subsequent call to the
//     |retrieveWithAnchor:limit:| method, above.  Using this anchor value will
//     return only locations which have been added to the location store since
//     the call to |getLatestAnchor| was made.

- (NSString*) getLatestAnchor;

// ==========================================================================

@end




