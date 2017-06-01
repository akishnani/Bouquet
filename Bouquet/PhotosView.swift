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
    func loadSavedPhotos() {
        store.loadSavedPhotos {
            [weak self](photosResult) -> Void in
            switch (photosResult) {
            case let .success(photos):
                print("Sucessfully loaded \(photos.count)")
                
                self?.flowerCount = photos.count
                
                //reinitialize the flower removed count
                self?.flowerRemoved = 0
                
                //search photos from flickr if count is zero.
                if (photos.count == 0) {
                    self?.searchPhotos()
                }
                
                //iterate through the list and randomly place images on the screeen
                for aPhoto in photos {
                    self?.fetchAndConfigureImage(aPhoto: aPhoto)
                }
                
            case let .failure(error):
                print("Error loading photos \(error)")
            }
        }
    }
    
    //saved photos
    func savePhotos() {
        
        bSavingInProgress = true
        
        //remove all the photos - only store the photos which are active on the screen
        store.removeAllPhotos()
        
        for aSubview in self.subviews {
            if let anImageView = aSubview as? PhotoImageView {
                
                //save the frame, position and the duration when the app moves in the background.
                anImageView.photo?.setFrame(frame: anImageView.frame)
                anImageView.photo?.setPosition(position: anImageView.layer.position)
                anImageView.photo?.setDuration(aDuration: anImageView.duration!)
                
                //save in stores photos collection for the active subview on the screen
                store.allPhotos.updateValue(anImageView.photo!, forKey: (anImageView.photo?.photoID)!)
                
                //remove it from the screen
                anImageView.removeFromSuperview()
                anImageView.layer.removeAnimation(forKey: "move")
                anImageView.image = nil
                print("removing::child subview count:\(self.subviews.count)")
            }
        }
        
        let success = store.savePhotos()
        if (success) {
            print("saved all of the \(store.allPhotos.count) photos")

        } else {
            print("could not save photos")
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
                let anImageView = PhotoImageView(frame: imageRect, imageData: image, aPhoto :aPhoto)
                
                //basket view to drop the UIImageView
                anImageView.basketImageView = self.basketImageView
                
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
                
                let movement = CABasicAnimation(keyPath: "position")
                movement.fromValue = NSValue(cgPoint: imagePosition)
                movement.toValue = NSValue(cgPoint: toPoint)
                movement.duration = randomDuration                
                movement.delegate = self
                //store a key value pair reference to imageview
                movement.setValue(anImageView, forKey: "imageView")
                
                anImageView.layer.position = toPoint
                anImageView.layer.add(movement, forKey: "move")
                
                //add imageView to the root view as a subview
                self.addSubview(anImageView)
                
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
            var anImageView:PhotoImageView? = anim.value(forKey: "imageView") as? PhotoImageView
            if (anImageView != nil) {
                anImageView?.removeFromSuperview()
                anImageView?.layer.removeAnimation(forKey: "move")
                anImageView?.image = nil
                anImageView = nil
                print("removing::child subview count:\(self.subviews.count)")
            }
            
        }
    }
}
