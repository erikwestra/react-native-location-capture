# react-native-location-capture #

A native module for [React Native](https://github.com/facebook/react-native)
that lets you capture the user's location, either on demand or periodically in
the background, even while the phone is asleep.  When running in background
mode, the captured locations are stored in an SQLite database, and can
optionally be uploaded to a remote server.

## Installation ##

 1. Download the source code to this module and store it somewhere permanent.

 2. `cd` into the `react-native-location-capture` directory and type:
 
        npm link

    This creates a symlink to the module in the global npm package list.

 3. `cd` into your own React Native application's directory and type:
 
        npm link react-native-location-capture
        
    This will insert a symlink to the location capture module into your app's
    `node_modules` directory.

## Building for iOS ##

 1. Open your app's .xcodeproj or .xcodeworkspace file in Xcode.
 
 2. Select the project navigator and right-click on the `Libraries` entry.  In
    the pop-up menu, select the "Add Files to XXX" item.  Navigate to
    `node_modules/react-native-location-capture` and add the
    `LocationCapture.xcodeproj` file to your project.

 2. Still in the project navigator, select your project (the top-most entry in
    the list), and select the "Build Phases" tab.  About halfway down is an
    enty named "Link Binary with Libraries".  Expand this item and click on the
    "+" button, then select the `libLocationCapture.a` library file.  Make sure
    this is added to the bottom of the file [I'm not sure if this is important
    or not, but I had dependency problems and this seemed to fix it].

 3. While you're there, click on "+" again and add the `libsqlite3.tbd` library
    to your project (if it isn't already there).  This allows the Location
    Capture module to access the SQLite database.

 4. Click on the `LocationCapture.xcodeproj` file you added earlier to the
    project navigator and select the "Build Settings" tab.  Make sure the "All"
    option is selected, and look for an entry named "Header Search Paths" in
    the "Search Paths" section.  Double click on this line, and in the pop-up
    window that appears click on the "+" button.  Type
    `$(SRCROOT)/../react-native/React`, and make sure the entry is marked as
    recursive.  Then click on "+" again, and type "$(SRCROOT)/../../React".
    Once again, mark this entry as recursive, and then close the pop-up window.

 5. Select your app's main project (at the top of the list), and click on the
    "Capabilities" tab.  Enable the "Background Modes" option.  Click on the
    "Location updates" checkbox to enable background updates.
   
 6. In the list of files on the left side of the window, find the app's
    "info.plist" file and right-click on it to bring up the pop-up menu.
    Select "Open As", and then "Source Code".  Look for any existing entries
    starting with `NSLocation`; replace these with the following:

        <key>NSLocationAlwaysUsageDescription</key>
        <string>I want to capture your location in the background.</string>
        <key>NSLocationWhenInUseUsageDescription</key>
        <string>I want to capture your location in the foreground.</string>

    Obviously you can change the wording as required (the string values must
    not be blank).  Save the file.

You can now build and run the app.  Note that if you change anything in the
location capture module itself, you will need to run the `Clean` command
(Command-Shift-K) before you can build the app.

## Building for Android ##

More to come...

## Usage ##

To use the Location Capture module, simply `require` the JS wrapper module:

```js
const LocationCapture = require('react-native-location-capture');
```

You can then access the various functions described below.  For example:

```js
LocationCapture.get_current().then(...);
```

## Available Functions ##

###get\_current()###

Retrieve the current GPS location.  Returns a promise which gets resolved once
the location has been retrieved.  Note that background geolocation does not
have to be enabled for this function to work.  If necessary, the user will be
asked if they allow us to obtain the device's current location.

The promise will be resolved with an object containing the details of the GPS
location.   This object will have the following fields:

`latitude`

> The device's current latitude, as a floating point number.

`longitude`

> The device's current longitude, as a floating point number.

`accuracy`

> A measure of the accuracy of the GPS location, in metres.

`heading`

> The direction the user is heading in, measured in degrees clockwise from
> North.  If this cannot be calculated, the heading will be set to -1.

`speed`

> The user's current speed, in metres per second.  If this can not be
> calculated, the speed will be set to -1.

If the current GPS location cannot be retrieved for some reason, the promise
will be rejected with a string value indicating what went wrong.  The following
rejection values are currently supported:

 * `UNAVAILABLE` Background geolocation is not available on this device.  This
   is either because the device does not support background geolocation, or
   because the user has turned off location services.

 * `DENIED` The user denied the request to access the device's location.

###configure(options)###

Configure the location capture module.  `options` should be an object
containing key-value pairs defining the various options to configure.  Note
that only the key-value pairs defined in `options` will be changed; the
`configure()` function can be called as often as desired, and only the supplied
options will be changed.

The following options can be configured using this function:

`time_filter`

> The number of seconds to wait between recording GPS locations.  Note that
> this represents a minimum value; because of the sporadic nature of GPS
> recordings, the actual time between recordings may be longer than this
> minimum.
>  
> Default = 30.

`distance_filter`

> The minimum distance the device must move before a new GPS location is
> recorded, in metres.  Once again, because of the sporadic nature of GPS
> recordings, the actual distance between recorded locations may be greater
> than this minimum.
> 
> Default = 0.

`upload_enabled`

> Should recorded locations be uploaded to a remote server?
> 
> Default = false.

`upload_url`

> The URL to send recorded locations to.
> 
> There is no default value for this option.

`upload_connection_type`

> The type of connection which will be used to upload the recorded locations.
> The following values are supported:
> 
> * `WIFI_ONLY` Only upload locations to the remote server when we have a
>   wifi connection.
>
> * `WIFI+CELLULAR` Upload locations to the remote server whenever we have
>   either a wifi or cellular data connection.
>
> Default = "WIFI+CELLULAR".

`upload_frequency`

> How often to send the recorded locations to the server.  If this is set to
> zero, the locations will be uploaded as soon as they are recorded.  The
> location capture module will only upload the recorded locations to the server
> if there has been at least this number of seconds since the last upload.
> Note that the frequency value represents the minimum time between uploads;
> because GPS locations are only received sporadically, the actual time between
> uploads may be greater than the specified frequency.
>
> Default = 0.

`upload_request_format`

> The format to use for encoding requests to be uploaded to the server.  The
> following request formats are currently supported:
> 
> * `JSON`
> * `FORM_URL_ENCODED`
> 
> Default = "JSON".

`upload_locations_param`

> The name of the parameter to use for holding the array of uploaded locations.
> 
> Default = "locations".

`upload_extra_params`

> An object containing additional parameters to send along with the locations.
> This can be used to send authentication details along with the upload, as
> well as other information such as the ID of the user these locations are for.
> 
> Default = None.

`upload_extra_headers`

> An object containing extra headers to include with the HTTP request sent to
> the server.  This can be used to send authentication details along with the
> upload, as required.

`upload_fields`

> An array of fields to include for each recorded location.  The following
> fields are currently supported:
> 
> * `timestamp` The date and time at which the location was recorded, as an
>   RFC-3339 format string.  Note that this timestamp will include the user's
>   current time zone offset. 
> 
> * `latitude` The latitude of the recorded location, as a floating-point
>   number.
>
> * `longitude` The longitude of the recorded location, as a floating-point
>   number.
> 
> * `accuracy` The accuracy of the received location, in metres.
> 
> * `heading` The direction the user is currently heading in, measured in
>   degrees clockwise from due north.  This will be set to -1 if the heading
>   cannot be calculated.
> 
> * `speed` The user's current speed, in metres per second.  This will be set
>   to -1 if the speed cannot be calculated.
> 
> Default = ["timestamp", "latitude", "longitude"].

`keep_locations_for`

> The number of days to store locations for in the local database.  If this is
> set to -1, the locations will be kept in the database forever.
>
> Default = 30.

###set\_notifier(notifier)###

Set a notifier function to call whenever a new location is recorded and the app
is running in the background.

The given Javascript function will be called (with no parameters) whenever one
or more locations have been recorded.  The locations will have already been
added to the internal database of recorded locations; this means that the
`retrieve()` function can be used to access these locations.

Note that notifications cannot be sent while the app is in the background; it
is up to the app to look for any new locations which may have been recorded
when the app moves into the foreground again.

###start()###

Start recording locations.  This starts up the background geolocator, possibly
asking the user for permission to access their location.  Locations will be
recorded, and the registered notifier function will be called if the app is
currently in the foreground.  Periodically, the recorded locations will also be
uploaded to the remote server if we have been configured to do so.

Note that background geolocation is a battery-intensive process, and so should
not be left on unnecessarily.

This function returns a promise that will be resolved with a string indicating
the success or failure of the attempt to start up background geolocation.  The
following success or failure values are currently supported:

 * `OK` Background geolocation was successfully started.

 * `UNAVAILABLE` Background geolocation is not available on this device.  This
   is either because the device does not support background geolocation, or
   because the user has turned off location services.

 * `DENIED` The user denied the request to access the device's location.

###stop()###

Turn off the recording of locations.  This function returns a promise that will
get resolved with the value `OK` once the background geolocator has been shut
down.

###retrieve(anchor, limit)###

Retrieve some recorded locations from the internal database.

The parameters are as follows:

`anchor`

> A string identifying the last point at which we retrieved locations from the
> database.  This is used to ensure that we only retrieve locations that we
> haven't seen before.  Pass null to retrieve the first (or oldest) locations
> in the database.

`limit`

> The maximum number of locations to retrieve at any one time.  Set to -1 to
> retrieve all the remaining locations.

Note that using a limit of -1 is not generally recommended as there may be a
large number of locations to retrieve, especially if the app was recording in
the background when the phone was asleep for some time.  This can cause the app
to run out of memory and crash when serialising the locations into JSON format
for transfer back to the Javascript code.

This function returns a Javascript promise that will get resolved with an
object with the following fields:

`locations`

> An array containing up to limit locations which have been received since the
> given anchor point.
> 
> Each array entry will be an object with the following fields:
> 
> * `timestamp` The date and time at which this location was recorded, as an
>   RFC-3339 format string.  Note that this timestamp will include the user's
>   current time zone offset. 
> 
> * `latitude` The latitude of the recorded location, as a floating-point
>   number.
>
> * `longitude` The longitude of the recorded location, as a floating-point
>   number.
>
> * `accuracy` The accuracy of the received location, in metres.
>
> * `heading` The direction the user is currently heading in, measured in
>   degrees clockwise from due north.  This will be set to -1 if the heading
>   cannot be calculated.
>
> * `speed` The user's current speed, in metres per second.  This will be set
>   to -1 if the speed cannot be calculated.
> 
> Note that this array will be empty if no new locations have been received
> since the given anchor value.

`next_anchor`

> The anchor value to use the next time this function is called to retrieve the
> next consecutive chunk of locations.

Note that this promise will never be rejected.

By repeatedly calling this function until the returned locations array is
empty, you can scan through the entire database of recorded locations in chunks
of limit locations at a time.

Each time this function is called, the returned `next_anchor` value should be
stored away and used as the anchor parameter when calling the function again.
This ensures that the same location is not retrieved twice, and that locations
are retrieved in the correct sequence.

###get\_latest\_anchor()###

Returns a promise that gets resolved with the latest anchor value to use when
calling the `retrieve()` function, above.  Using the returned anchor causes
`retrieve()` to only return locations which have been added since the call to the
`get_latest_anchor()` function was made.

