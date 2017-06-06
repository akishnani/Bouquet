//
//  PhotosView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/25/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotosView: UIView,CAAnimationDelegate {
    
    var flowerCount:Int = 0
    var flowerRemoved:Int = 0
    var bSavingInProgress:Bool = false
    
    //singleton photostore
    var store:PhotoStore = PhotoStore.sharedInstance
    
    //navcontroller for calculating height
    public var navController:UINavigationController? = nil
    
    //basket image view for favorites basket
    var basketImageView:UIImageView? = nil
    
    /// Container views which serve as a context for the view transition
    var containerViews = [String:UIView]()
    
    /// Views which are exchanged with image views for the view transition
    var metaDataViews = [String:UIView?]()
    
    /// image views for the view transition
    var imageViews = [String:UIView?]()
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"doubleTapNotification"),
                       object:nil, queue:nil,
                       using:handleDoubleTapNotification)
        
        //animationStopped Notification handler
        nc.addObserver(forName:Notification.Name(rawValue:"animationFinishedNotification"),
                       object:nil, queue:nil,
                       using:handleAnimationFinishedNotification)
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
    
    override func willRemoveSubview(_ subview: UIView) {
        
        if (bSavingInProgress) {
            return
        }

        //update the flower removed count
        flowerRemoved += 1
        
        if (flowerRemoved >= flowerCount) {
            flowerRemoved = 0
            self.searchPhotos()
        }
    }

    
    func searchPhotos() {
        
        store.searchPhotos {
            [weak self](photosResult) -> Void in
            
            switch (photosResult) {
            case let .success(photos):
                print("Sucessfully found \(photos.count)")
                self?.flowerCount = photos.count
                
                //iterate through the list and randomly place images on the screeen
                for aPhoto in photos {
                    self?.fetchAndConfigureImage(aPhoto: aPhoto)
                }
                
            case let .failure(error):
                print("Error searching photos \(error)")
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
            self.searchPhotos()
            return
        }
        
        self.flowerCount = (photos?.count)!
        
        //reinitialize the flower removed count
        self.flowerRemoved = 0
        
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
            for aPhoto in photos! {
                self.fetchAndConfigureImage(aPhoto: aPhoto)
            }
        }
    }
    
    //saved photos
    func savePhotos(bActivePhotos:Bool) {
        
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
        
        
        var bSuccess:Bool = false
        if (bActivePhotos) {
            bSuccess = store.saveActivePhotos()
        } else {
            bSuccess = store.savePhotos()
        }
        
        bSavingInProgress = false
    }
    
    func fetchAndConfigureImage(aPhoto:Photo) {
        store.fetchImage(for: aPhoto) {
            (imageResult) -> Void in
            
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
                let toY = self.frame.size.height + imageRect.size.height/2
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
                self.containerViews.updateValue(containerView, forKey: aPhoto.photoID)
                
                let movement = CABasicAnimation(keyPath: "position")
                movement.fromValue = NSValue(cgPoint: imagePosition)
                movement.toValue = NSValue(cgPoint: toPoint)
                movement.duration = randomDuration
                movement.delegate = self
                
                //store a key value pair reference to imageContainerView
                movement.setValue(containerView, forKey: "containerView")
                
                containerView.layer.position = toPoint
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
        
        //calculate a random Point
        let maxX:UInt32 = UInt32(self.frame.size.width)
        let maxY:UInt32 = UInt32(self.frame.size.height)
        
        var aRandomPoint = CGPoint(x:Int(arc4random_uniform(maxX)),y:Int(arc4random_uniform(maxY)))
        
        //get the nav bar height + status bar height
        let navBarHeight = (self.navController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.height
        
        if (aRandomPoint.y < navBarHeight) {
            //displace it by navBarHeight
            aRandomPoint.y = aRandomPoint.y + navBarHeight
        }
        
        //get a random width and height
        let imageWidth:CGFloat = CGFloat(arc4random_uniform(200)) + 50
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
                for aSubview in (aContainerView?.subviews)! {
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
                aContainerView?.removeFromSuperview()
                aContainerView?.layer.removeAllAnimations()
                self.containerViews.removeValue(forKey: (aContainerView?.photo.photoID)!)
                print("removing::child subview count:\(self.subviews.count)")
            }
        }
    }
}
