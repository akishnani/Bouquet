//
//  PhotosView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/25/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

enum ViewingMode {
    case normal
    case favorites
}

class PhotosView: UIView,CAAnimationDelegate {
    
    let maxFlowerCount = 15 //account for basket view and its constraints = 3 subviews , so 12 views is max on the screen (1 dozen of flowers)
    
    //number of outstanding calls to images to be fetched in pipeline - wait for these calls to return.
    var pendingFetchFlowerCount = 0
    
    //saving is in progress
    var bSavingInProgress:Bool = false
    
    //if searching Flickr photos http call is in progress
    var bHTTPRequestingPhoto = false
    
    //singleton photostore
    var store:PhotoStore = PhotoStore.sharedInstance
    
    //navcontroller for calculating height
    public var navController:UINavigationController? = nil
    
    //basket image view for favorites basket
    var basketImageView:UIImageView? = nil
    
    /// Container views which serve as a context for the view transition
    var containerViews = [String:UIView]()
    
    /// metadata which are exchanged with image views for the view transition
    var metaDataViews = [String:UIView?]()
    
    /// image views for the view transition
    var imageViews = [String:UIView?]()
    
    //photos array which consists of photos still to be fetched - managed by inventoryUpdate method
    var photosToBeFetched = [Photo]()
    
    //favorites photos
    var favoritesPhotos = [Photo]()
    
    //default viewing mode
    var viewingMode:ViewingMode = ViewingMode.normal
    
    //timer to re-request a new batch of flowers
    weak var timer: Timer?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let nc = NotificationCenter.default
        
        //doubleTapNotification on image view to do the flip animation.
        nc.addObserver(forName:Notification.Name(rawValue:"doubleTapNotification"),
                       object:nil, queue:nil,
                       using:handleDoubleTapNotification)
        
        //animationStopped Notification handler
        nc.addObserver(forName:Notification.Name(rawValue:"animationFinishedNotification"),
                       object:nil, queue:nil,
                       using:handleAnimationFinishedNotification)
        
        //animationStopped Notification handler
        nc.addObserver(forName:Notification.Name(rawValue:"addToFavoritesNotification"),
                       object:nil, queue:nil,
                       using:handleAddToFavoritesNotification)
        
        //add a double tap gesture on photos view
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotosView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
    }
    
    func viewWillAppear() {
        
        //initialize the badge manager instance and register the view
        let aBadgeValue = TIPBadgeManager.sharedInstance.getBadgeValue("favoritesBadge")
        if aBadgeValue == nil {
            TIPBadgeManager.sharedInstance.addBadgeSuperview("favoritesBadge", view: self.basketImageView!)
            TIPBadgeManager.sharedInstance.setBadgeValue("favoritesBadge", value: 0)
        }

        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.inventoryUpdate), userInfo: nil, repeats: true);
    }
    
    func viewWillDisappear() {
        if let timer = self.timer {
            print("Suspending Inventory Update")
            timer.invalidate()
        }
    }

    
    func inventoryUpdate() {
        
        //if the favorites mode is on - skip the update cycle which is only used in .normal mode
        if (viewingMode == .favorites) {
            return
        }

        //if the httprequest is in progress - skip the update cycle
        if (self.bHTTPRequestingPhoto) {
            return
        }
        
        
        let nFlowerViewCount:Int = self.subviews.count
        var httpFetchMore = false
        let delta = self.maxFlowerCount - nFlowerViewCount
        
        if (delta > 0) {
            if (self.photosToBeFetched.count >= delta) {
                    if (self.pendingFetchFlowerCount == 0) {
                        
                        print("inventoryUpdate delta:\(delta) and  photosToBeFetched count:\(self.photosToBeFetched.count)")

                        for  photoIndex in 0..<delta {
                            self.fetchAndConfigureImage(aPhoto: photosToBeFetched[photoIndex])
                        }
                        
                        //number of outstanding calls to images to be fetched in pipeline - wait for these calls to return.
                        self.pendingFetchFlowerCount = delta
                        
                        //remove the elements from the array once they are fetched.
                        for _ in 0..<delta {
                            photosToBeFetched.remove(at: 0)
                        }
                    }
            } else {
                print("requesting more http data...")
                httpFetchMore = true
            }
        } else {
            return
        }
        
        if (httpFetchMore) {
            //do a new http request for new photos
            print("inventoryUpdate::searchPhotos")
            self.searchPhotos()
        }            
    }
    
    func handleAnimationFinishedNotification(notification:Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let aSubView = userInfo["subView"] else {
                print("no user info found in notifiction")
                return
        }
        
        if let imageView = aSubView as? PhotoImageView {
            self.imageViews.removeValue(forKey: imageView.photo.photoID)
            //remove the container view
            self.containerViews.removeValue(forKey: imageView.photo.photoID)
        }
        
        if let metaDataView = aSubView as? MetaDataView {
            self.metaDataViews.removeValue(forKey: metaDataView.photo.photoID)
            //remove the container view
            self.containerViews.removeValue(forKey: metaDataView.photo.photoID)
        }
    }

    
    func handleDoubleTapNotification(notification:Notification) -> Void {
          guard let userInfo = notification.userInfo,
                let aSubView = userInfo["subView"],
                let _ = userInfo["gestureRecognizer"] else {
            print("no user info found in notifiction")
            return
        }
        
        let options:UIViewAnimationOptions = [.transitionFlipFromLeft , .allowUserInteraction]
        
        if let imageView = aSubView as? PhotoImageView {
            let metaDataView = self.metaDataViews[imageView.photo.photoID]
            
            if let aMetaDataView = metaDataView {
                UIView.transition(from: imageView, to: aMetaDataView!, duration: 2.5, options: options)
                {(finished: Bool) in
                    
                }
            }
        }
        
        if let metaDataView = aSubView as? MetaDataView {
            let imageView = self.imageViews[(metaDataView.photo.photoID)]
            
            if let anImagView = imageView {
                UIView.transition(from: metaDataView, to: anImagView!, duration: 2.5, options: options)
                {(finished: Bool) in
                    
                }
            }
            
        }
    }
    
    func handleAddToFavoritesNotification(notification:Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let aPhoto = userInfo["photo"] else {
                print("no user info found in notifiction")
                return
        }
        
        if (viewingMode == .favorites) {
            //dont' add flowers to basket in favorites mode
            return
        }
        
        //store the added image in favorites collection - keep a max of 12 flowers
        if let photo = aPhoto as? Photo {
            if (self.favoritesPhotos.count < maxFlowerCount - 3) {
                let aBadgeValue = TIPBadgeManager.sharedInstance.getBadgeValue("favoritesBadge")
                if var badgeVal = aBadgeValue {
                    badgeVal += 1
                    TIPBadgeManager.sharedInstance.setBadgeValue("favoritesBadge", value: badgeVal)
                }
                self.favoritesPhotos.append(photo)
            }
        }
    }
    
    /*
     * double tap on the basket view - loads the favorite photos
     */
    func doubleTap(_ gestureRecognizer:UIGestureRecognizer) {
        //send a notification so that PhotosView can respond
        let point = gestureRecognizer.location(in: self)
        let basketRect = self.basketImageView?.frame
        if (basketRect?.contains(point))! {
            
            switch viewingMode {
            case .normal:
                //if no flowers have been added in the basket then return
                if (self.favoritesPhotos.count == 0) {
                    return
                }
                
                //toggle to favorites mode
                viewingMode = .favorites
                
                //set the navigation title to favorites
                let favoritesTitle = NSLocalizedString("Favorites", comment: "title for Favorites mode")
                self.navController?.navigationBar.topItem?.title = favoritesTitle
                
                //remove all the container subviews
                for aSubview in self.subviews {
                    if let aContainerView = aSubview as? ContainerView {
                        removeContainerView(aContainerView: aContainerView)
                    }
                }
    
                
                //load the images from the favorite collection
                for aPhoto in self.favoritesPhotos {
                    self.fetchAndConfigureImage(aPhoto: aPhoto)
                }
                
                //reset to zero
                self.favoritesPhotos.removeAll()
                TIPBadgeManager.sharedInstance.setBadgeValue("favoritesBadge", value: 0)

            case .favorites:
                //toggle to normal mode
                viewingMode = .normal
                //set the navigation title to favorites
                let bouquetTitle = NSLocalizedString("Bouquet", comment: "title for normal bouquet mode")
                self.navController?.navigationBar.topItem?.title = bouquetTitle

                self.pendingFetchFlowerCount = 0
                inventoryUpdate()
            }
        }
    }
    
    
    func searchPhotos() {
        
        bHTTPRequestingPhoto = true
        
        store.searchPhotos {
            [weak self](photosResult) -> Void in
            
            
            switch (photosResult) {
            case let .success(photos):
                print("Sucessfully found \(photos.count)")
                
                //iterate through the list and place them in array to be fetched later
                for aPhoto in photos {
                    self?.photosToBeFetched.append(aPhoto)
                }
                self?.bHTTPRequestingPhoto = false
                
            case let .failure(error):
                print("Error searching photos \(error)")
                self?.bHTTPRequestingPhoto = false
            }
        }
    }
    
    //load saved photos
    func loadSavedPhotos(bActivePhotos:Bool) {

        var photos:[Photo]? = nil
        if (bActivePhotos) {
            photos = (store.loadActivePhotos() ?? nil)
        } else {
            photos = (store.loadPhotos() ?? nil)
        }
        
        if (photos == nil) {
            return
        }
        
        //search photos from flickr if count is zero - not likely to hit
        //this condition since the upper check for nil will hit.
        if (photos?.count == 0) {
            self.searchPhotos()
            return
        }
        
        if (bActivePhotos) {
            for aPhoto in photos! {
                let aContainerView:ContainerView? = self.containerViews[aPhoto.photoID] as? ContainerView
                if (aContainerView != nil) {
                    if (aPhoto.bIsPaused == false) {
                        aContainerView?.reAddAnimation()
                    }
                }
            }
        } else  {
            //store in the photosToBeFetched collection which is managed by the inventory
            let photoCount:Int! = photos?.count
            for index in 0..<photoCount {
                self.photosToBeFetched.append((photos?[index])!)
            }
        }
    }
    
    //saved photos
    func savePhotos(bActivePhotos:Bool) -> Bool {
        
        var bSuccess:Bool = false
        
        bSavingInProgress = true
        
        //remove all the photos - only store the photos which are active on the screen
        if (bActivePhotos) {
            store.removeAllActivePhotos()
        }
        
        if (bActivePhotos) {
            for aSubview in self.subviews {
                if let aContainerView = aSubview as? ContainerView {
                    //store the duration property
                    aContainerView.photo.setFrame(frame: aContainerView.frame)
                    aContainerView.photo.setPosition(position: aContainerView.layer.position)
                    aContainerView.photo.setDuration(aDuration: aContainerView.duration)
                    aContainerView.photo.isPaused(bIsPaused: aContainerView.bPaused)
                    store.activePhotos.updateValue(aContainerView.photo, forKey: aContainerView.photo.photoID)
                }
            }
        }
        
        

        if (bActivePhotos) {
            bSuccess = store.saveActivePhotos()
        } else {
            bSuccess = store.savePhotos()
        }
        
        bSavingInProgress = false
        return bSuccess
    }
    
    func fetchAndConfigureImage(aPhoto:Photo) {
        store.fetchImage(for: aPhoto) {
            (imageResult) -> Void in
            
            //decrement the pending flower count
            if (self.viewingMode == .normal) {
                self.pendingFetchFlowerCount = self.pendingFetchFlowerCount - 1
            }
            
            switch imageResult {
            case let .success(image):
                
                //calculate the imageRect
                var imageRect:CGRect = CGRect.zero
                var imagePosition:CGPoint = CGPoint.zero
                
                if (aPhoto.frame != CGRect.zero) {
                    //retrive the frame from the saved photo class instance
                    imageRect = aPhoto.frame!
                    imagePosition = aPhoto.position!
                }
                else {
                    imageRect = self.calculateViewFrameForImageView()
                    imagePosition = CGPoint(x: imageRect.origin.x, y: imageRect.origin.y)
                }
                
                //create a UIImageview object from the data loaded from the internet (flickrAPI)
                var imageData:UIImage? = image
                let anImageView = PhotoImageView(frame: imageRect, imageData: &imageData, aPhoto :aPhoto)
                
                //basket view to drop the UIImageView
                //anImageView.basketImageView = self.basketImageView
                
                if (aPhoto.frame != CGRect.zero) {
                    //retrive the position from the saved photo
                    anImageView.layer.position = aPhoto.position!
                }
        
                //add an explicit animation
                let toX = imagePosition.x
                let toY = self.frame.size.height + imageRect.size.height
                let toPoint = CGPoint(x: toX, y: toY)
                var randomDuration:CFTimeInterval = 0.0
                
                if (aPhoto.frame != CGRect.zero) {
                    //retrive the position from the saved photo
                    randomDuration = aPhoto.duration!
                } else {
                    //randomize duration for a brand new image
                    randomDuration = CFTimeInterval(arc4random_uniform(10)) + 7.5
                }
                
                //save the duration - to readd it later
                anImageView.duration = randomDuration
                
                
                //creating a containerView specifically for flip transition
                let containerView = ContainerView(frame: imageRect, aPhoto:aPhoto,duration:randomDuration)
                containerView.isOpaque = false
                containerView.backgroundColor = UIColor.clear
                containerView.isUserInteractionEnabled = true
                containerView.basketImageView = self.basketImageView
                self.containerViews.updateValue(containerView, forKey: aPhoto.photoID)
                
                let movement = CABasicAnimation(keyPath: "position")
                movement.fromValue = NSValue(cgPoint: imagePosition)
                movement.toValue = NSValue(cgPoint: toPoint)
                movement.duration = randomDuration
                movement.delegate = self
                
                //store a key value pair reference to imageContainerView
                movement.setValue(containerView, forKey: "containerView")
                
                containerView.layer.position = toPoint
                containerView.layer.fillMode = kCAFillModeForwards
                containerView.layer.add(movement, forKey: "move")
                
                self.addSubview(containerView)
                anImageView.frame = anImageView.bounds
                containerView.addSubview(anImageView)
                
                //append it to imageviews used for transition
                
                if var oldImageView = self.imageViews.updateValue(anImageView, forKey: aPhoto.photoID) {
                    oldImageView = nil
                }
                
                self.imageViews.updateValue(anImageView, forKey: aPhoto.photoID)
                
                //store the metadata view correpsonding to the image
                let metaDataView:MetaDataView = MetaDataView(frame: anImageView.frame, aPhoto: aPhoto)
                if var oldMetaDataView = self.metaDataViews.updateValue(metaDataView, forKey: aPhoto.photoID)
                {
                    oldMetaDataView = nil
                }
                
                print("adding::total child subview count:\(self.subviews.count)")
                
            case let .failure(error):
                print("Error downloading image:\(error)")
            }
        }
    }
    
    
    func calculateViewFrameForImageView()->CGRect {

        //get the nav bar height + status bar height
        let navBarHeight = (self.navController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height
        
        //calculate a random Point
        let maxX:UInt32 = UInt32(self.frame.size.width)
        
        var aRandomPoint = CGPoint(x:Int(arc4random_uniform(maxX)),y:Int(arc4random_uniform(UInt32(navBarHeight))))
        
        //get a random width and height
        let imageWidth:CGFloat = CGFloat(arc4random_uniform(200)) + 100
        //make the imageWidth and height the same.
        let imageHeight:CGFloat = imageWidth
        
        
        var imageRect:CGRect = CGRect(x: aRandomPoint.x, y: aRandomPoint.y, width: imageWidth, height: imageHeight)
        let unionRect = self.frame.union(imageRect)
        
        //calculate if this imageRect is fully contained in the view
        if (unionRect != self.frame) {
            //which means that the position is need to be adjusted so it not placed offscreen
            let viewHeight = self.frame.size.height
            let viewWidth  = self.frame.size.width
            
            if ((aRandomPoint.y + imageHeight) > viewHeight ) {
                let deltaY = aRandomPoint.y + imageHeight - viewHeight
                aRandomPoint.y = aRandomPoint.y - deltaY
                imageRect.origin.y = aRandomPoint.y
            }
            
            if ((aRandomPoint.x + imageWidth) > viewWidth ) {
                let deltaX = aRandomPoint.x + imageWidth - viewWidth
                aRandomPoint.x = aRandomPoint.x - deltaX
                imageRect.origin.x = aRandomPoint.x
            }
        }
        
        return imageRect
    }
    
    /*
     * add a call to remove the image from superview when the animation is stopped.
     */
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            let aContainerView:ContainerView? = anim.value(forKey: "containerView") as? ContainerView
            if (aContainerView != nil) {
                removeContainerView(aContainerView: aContainerView!)
            }
        }
    }
    
    
    func removeContainerView(aContainerView:ContainerView) {
        for aSubview in (aContainerView.subviews) {
            if let anImageView = aSubview as? PhotoImageView {
                self.imageViews.removeValue(forKey: anImageView.photo.photoID)
                anImageView.removeFromSuperview()
                anImageView.image = nil
            }
            
            if let aMetaDataView = aSubview as? MetaDataView {
                aMetaDataView.removeFromSuperview()
                self.metaDataViews.removeValue(forKey: (aMetaDataView.photo.photoID))
            }
        }
        aContainerView.layer.removeAllAnimations()
        aContainerView.removeFromSuperview()
        self.containerViews.removeValue(forKey: aContainerView.photo.photoID)
        print("removing::child subview count:\(self.subviews.count)")
    }
}
