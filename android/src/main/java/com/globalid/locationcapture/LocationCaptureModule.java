// ##########################################################################
//
// LocationCaptureModule.java
//
// This file contains the Java implementation for the LocationCapture native
// module on the Android platform.
//
// ##########################################################################

package com.globalid.locationcapture;

import java.util.List;
import java.util.HashMap;
import java.util.ArrayList;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;

import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.LocationProvider;

// ##########################################################################

class CurrentLocationListener implements LocationListener {

    Promise promise;

    public CurrentLocationListener(Promise promise) {
        super();
        this.promise = promise;
    }

    public void onLocationChanged(Location location) {
        if (this.promise != null) {
            WritableMap results = Arguments.createMap();

            results.putDouble("latitude", location.getLatitude());
            results.putDouble("longitude", location.getLongitude());
            results.putDouble("accuracy", location.getAccuracy());
            results.putDouble("heading", location.getBearing());
            results.putDouble("speed", location.getSpeed());

            this.promise.resolve(results);
            this.promise = null;
        }
    }

    public void onStatusChanged(String provider,
                                int status,
                                Bundle extras) {
        if (this.promise != null) {
            if (status == LocationProvider.OUT_OF_SERVICE) {
                this.promise.reject("OUT OF SERVICE", "");
            } else if (status == LocationProvider.TEMPORARILY_UNAVAILABLE) {
                this.promise.reject("TEMPORARILY UNAVAILABLE", "");
            }
            this.promise = null;
        }
    }

    public void onProviderEnabled(String provider) {
    }

    public void onProviderDisabled(String provider) {
        if (this.promise != null) {
            this.promise.reject("DENIED", "");
            this.promise = null;
        }
    }
}

// ##########################################################################

public class LocationCaptureModule extends ReactContextBaseJavaModule {

    private Context context;
    private int     time_filter;
    private int     distance_filter;
    private boolean upload_enabled;
    private String  upload_url;
    private String  upload_connection_type;
    private int     upload_frequency;
    private String  upload_request_format;
    private String  upload_locations_param;
    private HashMap upload_extra_params;
    private List    upload_fields;
    private int     keep_locations_for;

    public LocationCaptureModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context                = reactContext;
        this.time_filter            = 30;
        this.distance_filter        = 0;
        this.upload_enabled         = false;
        this.upload_connection_type = "WIFI+CELLULAR";
        this.upload_frequency       = 0;
        this.upload_request_format  = "JSON";
        this.upload_locations_param = "locations";
        this.upload_extra_params    = new HashMap();
        this.upload_fields          = new ArrayList();
        this.keep_locations_for     = 30;

        this.upload_fields.add("timestamp");
        this.upload_fields.add("latitude");
        this.upload_fields.add("longitude");
    }

    @Override
    public String getName() {
        return "LocationCapture";
    }

    @ReactMethod
    public void get_current(Promise promise) {

        Activity         activity;
        LocationManager  manager;
        LocationListener listener;

        activity = this.getCurrentActivity();
        manager  = (LocationManager)activity.getSystemService(
                                                Context.LOCATION_SERVICE);

        if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            listener = new CurrentLocationListener(promise);

            manager.requestSingleUpdate(LocationManager.GPS_PROVIDER,
                                        listener, null);
        } else {
            promise.reject("NO GPS PROVIDER", "");
        }
    }

    @ReactMethod
    public void configure(ReadableMap options) {

        if (options.hasKey("time_filter")) {
            this.time_filter = options.getInt("time_filter");
        }

        if (options.hasKey("distance_filter")) {
            this.distance_filter = options.getInt("distance_filter");
        }

        if (options.hasKey("upload_enabled")) {
            this.upload_enabled = options.getBoolean("upload_enabled");
        }

        if (options.hasKey("upload_url")) {
            this.upload_url = options.getString("upload_url");
        }

        if (options.hasKey("upload_connection_type")) {
            this.upload_connection_type = options.getString(
                                            "upload_connection_type");
        }

        if (options.hasKey("upload_frequency")) {
            this.upload_frequency = options.getInt("upload_frequency");
        }

        if (options.hasKey("upload_request_format")) {
            this.upload_request_format = options.getString(
                                            "upload_request_format");
        }

        if (options.hasKey("upload_locations_param")) {
            this.upload_locations_param = options.getString(
                                            "upload_locations_param");
        }

        if (options.hasKey("upload_extra_params")) {
            ReadableMap extra_params = options.getMap("upload_extra_params");
            ReadableMapKeySetIterator iterator = extra_params.keySetIterator();

            this.upload_extra_params.clear();
            while (iterator.hasNextKey()) {
                String key   = iterator.nextKey();
                String value = extra_params.getString(key);

                this.upload_extra_params.put(key, value);
            }
        }

        if (options.hasKey("upload_fields")) {
            ReadableArray upload_fields = options.getArray("upload_fields");

            this.upload_fields.clear();
            for (int i=0; i < upload_fields.size(); i++) {
                this.upload_fields.add(upload_fields.getString(i));
            }
        }

        if (options.hasKey("keep_locations_for")) {
            this.keep_locations_for = options.getInt("keep_locations_for");
        }

        // TODO: Update background task to reflect changed options.
    }

    @ReactMethod
    public void start(Promise promise) {
        promise.reject("NOT YET", "");
    }

    @ReactMethod
    public void stop(Promise promise) {
        promise.reject("NOT YET", "");
    }

    @ReactMethod
    public void retrieve(String anchor, int limit, Promise promise) {
        promise.reject("NOT YET", "");
    }

    @ReactMethod
    public void getLatestAnchor(Promise promise) {
        promise.reject("NOT YET", "");
    }
}

