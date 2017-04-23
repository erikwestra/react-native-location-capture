// ##########################################################################
//
// LocationCaptureDBRetrieveResult.java
//
// This file implements the LocationCaptureDBRetrieveResult class.
//
// ##########################################################################

package com.globalid.locationcapture;

import java.util.List;

// ##########################################################################
//
// LocationCaptureDBRetrieveResult
//
//     This class encapsulates the two values returned by a call to the
//     LocationCaptureDB.retrieveFromLocationStore() method.

public class LocationCaptureDBRetrieveResult {
    private List<CapturedLocation> locations;
    private String                 next_anchor;

    public LocationCaptureDBRetrieveResult(List<CapturedLocation> locations,
                                           String next_anchor) {
        this.locations   = locations;
        this.next_anchor = next_anchor;
    }

    public List<CapturedLocation> getLocations() {
        return this.locations;
    }

    public String getNextAnchor() {
        return this.next_anchor;
    }
}

