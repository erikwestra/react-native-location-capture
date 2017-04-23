// ##########################################################################
//
// LocationUploader.java
//
// This file defines the "LocationUploader" class.  This class handles the
// uploading of captured locations to a remote server.
//
// Note that the app must have android.permission.ACCESS_NETWORK_STATE
// permission for this class to work.
//
// ##########################################################################

package com.globalid.locationcapture;

import java.util.List;
import java.util.HashMap;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

// ##########################################################################

public class LocationUploader {

    private Context context;

    // ======================================================================
    //
    // LocationUploader()
    //
    //     Standard constructor.

    public LocationUploader(Context context) {

        this.context = context;
    }

    // ======================================================================
    //
    // uploadLocations(locations, url, format, locations_param,
    //                 extra_params, upload_fields)
    //
    //     Attempt to upload a list of locations to the remote server.
    //
    //     The parameters are as follows:
    //
    //         'locations'
    //
    //             A List of CapturedLocation objects.
    //
    //         'url'
    //
    //             The URL to upload the locations to.
    //
    //         'format'
    //
    //             The desired format to use for uploading the locations.  This
    //             should be either "JSON" or "FORM_URL_ENCODED".
    //
    //         'locations_param'
    //
    //             The name of the parameter to use for holding the array of
    //             uploaded locations.
    //
    //         'extra_params'
    //
    //             A HashMap containing additional parameters to send along
    //             with the locations.
    //
    //         'upload_fields'
    //
    //             A List of strings containing the fields to upload for each
    //             location.  The following field names are supported:
    //
    //                 "timestamp"
    //                 "latitude"
    //                 "longitude"
    //                 "accuracy"
    //                 "heading"
    //                 "speed"
    //
    //     We attempt to upload the given list of locations to the given server
    //     using the supplied parameters.  Upon completion, we return |true|
    //     if the locations were successfully uploaded, or |false| otherwise.
    //
    //     Note that this method should be called from within an asynchronous
    //     task.

    public boolean uploadLocations(List<CapturedLocation> locations,
                                   String url,
                                   String format,
                                   String locations_param,
                                   HashMap<String,String> extra_params,
                                   List<String> upload_fields) {
        return false; // Lots more to come...
    }

    // ======================================================================
    // ==                                                                  ==
    // ==                  P R I V A T E   M E T H O D S                   ==
    // ==                                                                  ==
    // ======================================================================
    //
    // hasNetworkConnection()
    //
    //     Return |true| if and only if we have a current internet connection.

    private boolean hasNetworkConnection() {
        ConnectivityManager manager = (ConnectivityManager)
                    this.context.getSystemService(Context.CONNECTIVITY_SERVICE);

        NetworkInfo network_info = manager.getActiveNetworkInfo();

        if ((network_info != null) && network_info.isConnected()) {
            return true;
        } else {
            return false;
        }
    }
}

