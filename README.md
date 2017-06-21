# Bouquet
FlickrAPI to display images in circles and gesture recognizers to interact with them and save/restore them.

PhotoStore.swift class does async network calls to retrieve photos from FlickrAPI.swift class.

PhotoStore.swift also has the responsibility of storing and retrieving the photos from the persistent storage using NSKeyedArchiver & NSKeyedUnarchiver

In addition this is backed by ImageStore cache class which caches images in memory and on disk for faster retrieval indexed by key "photoID"

Each Photo.swift model class has a corresponding view class PhotoImageView.swift


Currently the project has the following features which are in working state:

-   it displays the photos of flowers from Flickr
-   the flowers glide down the screen with varying sizes and velocity and position
-   the user can interact with flowers tap to stop , drag to move , pinch to zoom in/zoom out
-   the image location, size and velocity are stored when the app moves in background and restored when the app moves in the active state
-   continious stream of images
-   uses the saved images for a faster launch
-   added favorites basket where user can drag and drop flowers into
-   allowing users to only display images from favorite basket
-   displaying the image meta data by double tapping on the flower using "flip" animation
-   adjust image keyword search according to user’s default language setting

Features still to be implemented:

-   ignoring users gestures on transparent areas of imageview

In order to run the project:

-   please sync to github public repo : https://github.com/akishnani/Bouquet
-   please connect the mobile device using the USB cable
-   run the app on the device since the memory footprint is different than the memory footprint on the simulator

©2017 Amit Kishnani

-----
Verion 1.9
-   continious flow of flowers when in favorites mode
-   added a timer which fires every quater second (0.25) and calls the favoritesUpdate which manages display of flowers in favorites mode

-----
Verion 1.8
-   shrink animation when the flower is dropped into the basket

-----
Verion 1.7

-   added files from [TIPBadgeManager](https://github.com/johncosch/TIPBadgeManager) badge manager to be added to any view
-   added support for favorites basket - drag & drop into the basket increments the badge value
-   double clicking on favorites basket - display only flowers from their favorites basket
-   maximum favorites flower count is 12 (dozen) to better handle memory requirements
-   adjust image keyword search according to user’s default language setting
-   added support for the following languages ( spanish, german, hindi)


-----
Verion 1.6

-   instead of immediately putting the flowers on the screen - they are queued up in a collection called “photosToBeFetched” and incrementally /gradually added on the screen so the flow of flowers appear continuous
-   to handle the above logic introduce a timer which runs every half second and does inventoryUpdate
-   made the flower basket view proportional to superview - so it can scale up and down accordingly

-----
Verion 1.5

-   saving retrieved images for faster relaunch user experience so user can be in the offline mode and we can still retrieve the saved photos
-   saving active photos displayed on the screen whether they are paused or in motion - so can restore them in between moving seamlessly between background to foreground/active state
-   added support for double tap which causes a “flip” animation to display the user meta data

-----

Version 1.4 persistence flower state and velocity and continuous stream of flowers (May 31, 2017)

-   the image location, size and velocity are stored when the app moves in background and restored when the app moves back in the active state using NSKeyedArchiver & NSKeyedUnarchiver
-   added support for continuous stream of flowers
-   added support for favorite basket view and when the flowers dragged & dropped in the basket they are removed from the screen

-----

Version 1.3 refactoring based on instructor feedback (May 21-22, 2017)

-    made PhotoStore a singleton class (simplified code removed from AppDelegate class)
-    removed the green border around PhotoImageView class
-    removed animation when gestures like drag/pinch are in progress
-    removed the CGPoint.random() extension
-    added a new function to configure the imageViewRect called "calculateViewFrameForImageView"
-    changed the name of the method from "fetchImage" to "fetchAndConfigureImage"
-    moved the set-up of imageview to PhotoImageView class
-    removed the imageView from the superview at the end of animation so they are no longer appearing in portrait mode when you switch from landscape to portrait
-    also cleaned up and refactored code into functions (like pauseAnimation, resumeAnimation, reAddAnimation)
-   removed "touchesBegan" method
-    added Pinch Gesture to expand/shrink the image

-----

Version 1.2 removed UIKit dynamics - using CoreAnimation instead (May 19, 2017)

-   added some more comments to PhotoImageView.swift class (specifically the CADisplayLink callback method)

-----


Version 1.1 UIImageView dynamically to view (images of different sizes) (May 15, 2017)

-   used layer.cornerRadius to generate circular images
-   experimented with UIKit Dynamics library for animation introduced in iOS7 (currently commented out)
-   instead implemented CoreAnimation for moving the images across the screen at different speeds

-----


Version 1.0 Initial Commit (May 6, 2017)

-   calling the Flickr search API (flickr.photos.search) and getting back/printing a JSON payload to the console
-   parses the json dictionary into Photo model objects and retrieves & displays the first photo in PhotosViewController
