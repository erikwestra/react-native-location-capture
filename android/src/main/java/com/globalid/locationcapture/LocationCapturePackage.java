// ##########################################################################
//
// LocationCapturePackage.java
//
// This file contains the Java code needed to register the LocationCapture
// module with the Reach Native app.
//
// ##########################################################################

package com.globalid.locationcapture;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.uimanager.ViewManager;

import java.util.List;
import java.util.Collections;
import java.util.ArrayList;

// ##########################################################################

public class LocationCapturePackage implements ReactPackage {

    // Needed?
    @Override
    public List<Class<? extends JavaScriptModule>> createJSModules() {
        return Collections.emptyList();
    }

    // Needed?
    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        return Collections.emptyList();
    }

    @Override
    public List<NativeModule> createNativeModules(
                                    ReactApplicationContext reactContext) {
        List<NativeModule> modules = new ArrayList();
        modules.add(new LocationCaptureModule(reactContext));
        return modules;
    }
}

