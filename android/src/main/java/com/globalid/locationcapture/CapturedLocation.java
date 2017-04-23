// ##########################################################################
//
// CapturedLocation.java
//
// This file defines the "CapturedLocation" class.  A CapturedLocation is an
// object encapsulating a captured location stored in the database.
//
// ##########################################################################

package com.globalid.locationcapture;

// ##########################################################################

public class CapturedLocation {

    private int    id;
    private long   timestamp;
    private double latitude;
    private double longitude;
    private int    accuracy;
    private double heading;
    private double speed;

    // ======================================================================
    //
    // Default constructor.

    public CapturedLocation() {}

    // ======================================================================
    //
    // Standard constructor.

    public CapturedLocation(long   timestamp,
                            double latitude,
                            double longitude,
                            int    accuracy,
                            double heading,
                            double speed) {
        super();
        this.timestamp = timestamp;
        this.latitude  = latitude;
        this.longitude = longitude;
        this.accuracy  = accuracy;
        this.heading   = heading;
        this.speed     = speed;
    }

    // ======================================================================
    //
    // Getters and setters.

    public int getId() {
        return this.id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public long getTimestamp() {
        return this.timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    public double getLatitude() {
        return this.latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return this.longitude;
    }

    public void setAccuracy(int accuracy) {
        this.accuracy = accuracy;
    }

    public int getAccuracy() {
        return this.accuracy;
    }

    public void setHeading(double heading) {
        this.heading = heading;
    }

    public double getHeading() {
        return this.heading;
    }

    public void setSpeed(double speed) {
        this.speed = speed;
    }

    public double getSpeed() {
        return this.speed;
    }

    // ======================================================================
    //
    // toString()
    //
    //     Return a string representation of this captured location, for
    //     debugging.

    @Override
    public String toString() {
        return "CapturedLocation [id=" + this.id +
                               ", timestamp=" + this.timestamp +
                               ", latitude=" + this.latitude +
                               ", longitude=" + this.longitude +
                               ", accuracy=" + this.accuracy +
                               ", heading=" + this.heading +
                               ", speed=" + this.speed + "]";
    }
}

