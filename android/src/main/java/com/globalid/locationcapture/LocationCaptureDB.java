// ##########################################################################
//
// LocationCaptureDB.java
//
// This file implements the SQLiteOpenHelper subclass for the location capture
// module.  It defines our database structure, along with helper methods for
// the location store and upload queue.
//
// ##########################################################################

package com.globalid.locationcapture;

import java.util.Date;
import java.util.List;

import android.content.Context;
import android.content.ContentValues;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

// ##########################################################################

public class LocationCaptureDB extends SQLiteOpenHelper {

    // Our database version:

    private static final int DATABASE_VERSION = 1;

    // The name for our database:

    private static final String DATABASE_NAME = "LocationCapture";

    // ======================================================================
    //
    // LocationCaptureDB(context)
    //
    //     Our standard constructor.

    public LocationCaptureDB(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    // ======================================================================
    //
    // onCreate(db)
    //
    //     Create our database schema.

    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE location_store(" +
                   "  id        INTEGER PRIMARY KEY," +
                   "  timestamp INTEGER," +
                   "  latitude  DOUBLE," +
                   "  longitude DOUBLE," +
                   "  accuracy  INTEGER," +
                   "  heading   DOUBLE," +
                   "  speed     DOUBLE)");

        db.execSQL("CREATE INDEX location_store_index " +
                   "ON location_store(timestamp)");

        db.execSQL("CREATE TABLE upload_queue(" +
                   "  id        INTEGER PRIMARY KEY," +
                   "  timestamp INTEGER," +
                   "  latitude  DOUBLE," +
                   "  longitude DOUBLE," +
                   "  accuracy  INTEGER," +
                   "  heading   DOUBLE," +
                   "  speed     DOUBLE)");

        db.execSQL("CREATE INDEX upload_queue_index " +
                   "ON upload_queue(timestamp)");
    }

    // ======================================================================
    //
    // onUpgrade(db, oldVersion, newVersion)
    //
    //     Upgrade our database to a new version.
    //
    //     Note that we simply delete the existing tables (if any) and then
    //     recreate them.

    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {

        db.execSQL("DROP TABLE IF EXISTS location_store");
        db.execSQL("DROP TABLE IF EXISTS upload_queue");

        this.onCreate(db);
    }

    // ======================================================================
    // ==                                                                  ==
    // ==            L O C A T I O N   S T O R E   H E L P E R S           ==
    // ==                                                                  ==
    // ======================================================================
    //
    // addToLocationStore(location)
    //
    //     Add a CapturedLocation to the location store table.

    public void addToLocationStore(CapturedLocation location) {

        SQLiteDatabase db = this.getWritableDatabase();

        ContentValues values = new ContentValues();
        values.put("timestamp", location.getTimestamp());
        values.put("latitude",  location.getLatitude());
        values.put("longitude", location.getLongitude());
        values.put("accuracy",  location.getAccuracy());
        values.put("heading",   location.getHeading());
        values.put("speed",     location.getSpeed());

        db.insert("location_store", null, values);
        db.close();
    }

    // ======================================================================
    //
    // deleteOldLocationsFromLocationStore(num_days)
    //
    //     Delete any locations in the location store older than the given
    //     number of days.

    public void deleteOldLocationsFromLocationStore(int num_days) {

        Date now      = new Date();
        long cur_secs = (long)now.getTime()/1000;
        long cutoff   = cur_secs - (num_days * 86400);

        SQLiteDatabase db = this.getWritableDatabase();
        db.delete("location_store", "timestamp < ?",
                  new String[] { String.valueOf(cutoff) });
        db.close();
    }

    // ======================================================================
    //
    // retrieveFromLocationStore(anchor, limit)
    //
    //     Retrieve a number of locations from the location store, based on
    //     the given anchor and limit values.
    //
    //     Upon completion, we return a LocationCaptureDBRetrieveResult object
    //     containing the list of retrieved locations and the next anchor value
    //     to use.

    public LocationCaptureDBRetrieveResult retrieveFromLocationStore(
                                                    String anchor,
                                                    int limit) {
        return null; // More to come...
    }

    // ======================================================================
    //
    // getLatestAnchorFromLocationStore()
    //
    //     Retrieve the latest anchor value for the most recent location in the
    //     location store.

    public String getLatestAnchorFromLocationStore() {

        return null; // More to come...
    }

    // ======================================================================
    // ==                                                                  ==
    // ==              U P L O A D   Q U E U E   H E L P E R S             ==
    // ==                                                                  ==
    // ======================================================================
    //
    // addToUploadQueue(location)
    //
    //     Add the given location to our upload queue.

    public void addToUploadQueue(CapturedLocation location) {

        // More to come...
    }

    // ======================================================================
    //
    // flushUploadQueue()
    //
    //     Retrieve the contents of the upload queue, and remove the locations
    //     from the queue.

    public List<CapturedLocation> flushUploadQueue() {

        return null; // More to come...
    }

    // ======================================================================
    //
    // restoreToUploadQueue(locations) {
    //
    //     Restore the contents of the upload queue.
    //
    //     The given locations are added back into the queue.  This is done
    //     when we could not upload the locations to the remote server for some
    //     reason.

    public void restoreToUploadQueue(List<CapturedLocation> locations) {

        // More to come...
    }
}

