// locationCapture.h
//
// This header file defines the LocationCapture class.  Because this is a React
// Native module, we don't define any public interfere here.

#import <CoreLocation/CoreLocation.h>

#import <RCTBridge.h>
#import <RCTEventEmitter.h>

// ##########################################################################

@interface LocationCapture : RCTEventEmitter <RCTBridgeModule, 
                                              CLLocationManagerDelegate>
@end

