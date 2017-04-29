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

# Building for iOS #

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

# Building for Android #

More to come...

