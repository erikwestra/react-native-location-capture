'use strict'

// ##########################################################################
//
// locationCapture.js
//
// This file contains the Javascript wrapper for the Global ID location capture
// module.  It provides the public interface for the "locationCapture" native
// module, which has an underlying implementation for both iOS and Android
// platforms.  The purpose of this wrapper module is to provide a simplified
// interface to the module, and to hide any platform-specific functionality
// away from the rest of the system.
//
// ##########################################################################

import {
    Platform,
    NativeModules,
    DeviceEventEmitter, // Android.
    NativeEventEmitter, // iOS.
} from 'react-native'

// ##########################################################################

class LocationCapture {

    // Public interface:

    static get_current() {
        return NativeModules.LocationCapture.get_current()
    }

    static configure(options) {
        NativeModules.LocationCapture.configure(options)
    }

    static set_notifier(notifier) {
        LocationCapture._notifier = notifier
    }

    static start() {
        return NativeModules.LocationCapture.start()
    }

    static stop() {
        return NativeModules.LocationCapture.stop()
    }

    static retrieve(anchor, limit) {
        return NativeModules.LocationCapture.retrieve(anchor, limit)
    }

    static get_latest_anchor() {
        return NativeModules.LocationCapture.getLatestAnchor()
    }

    // Used internally:

    static _notifier = null
}

// ##########################################################################

if (Platform.OS == 'ios') {

    // Listen for 'location_received' events on iOS.

    const emitter = new NativeEventEmitter(NativeModules.LocationCapture);

    emitter.addListener('location_received', function() {
        if (LocationCapture._notifier != null) {
            LocationCapture._notifier()
        }
    });

} else if (Platform.OS == 'android') {

    // Listen for 'location_received' events on Android.

    DeviceEventEmitter.addListener('location_received', function() {
        if (LocationCapture._notifier != null) {
            LocationCapture._notifier()
        }
    });
}

// ##########################################################################

module.exports = LocationCapture

