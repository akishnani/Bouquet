//
//  ViewController.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, CAAnimationDelegate {
    
    var store:PhotoStore = PhotoStore.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        store.searchPhotos {
            [weak self](photosResult) -> Void in
            switch (photosResult) {
                case let .success(photos):
                    print("Sucessfully found \(photos.count)")
                
                    //iterate through the list and randomly place images on the screeen
                    for aPhoto in photos {
                        self?.fetchAndConfigureImage(aPhoto: aPhoto)
                    }
                
                case let .failure(error):
                    print("Error searching photos \(error)")
                }
        }
    }
    
    
    func fetchAndConfigureImage(aPhoto:Photo) {
        store.fetchImage(for: aPhoto) {
            (imageResult) -> Void in
            
            switch imageResult {
            case let .success(image):
                aPhoto.imageData = image
                
                //calculate the imageRect
                let imageRect:CGRect = self.calculateViewFrameForImageView()
                let imagePosition:CGPoint = CGPoint(x: imageRect.origin.x, y: imageRect.origin.y)
                
                //create a UIImageview object from the data loaded from the internet (flickrAPI)
                let anImageView = PhotoImageView(frame: imageRect, imageData: image)
               
                //add an explicit animation
                let toX = imagePosition.x
                let toY = self.view.frame.size.height + imageRect.size.height/2
                let toPoint = CGPoint(x: toX, y: toY)
                let randomDuration:CFTimeInterval = CFTimeInterval(arc4random() % 5) + 10
                
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
                self.view.addSubview(anImageView)
                
            case let .failure(error):
                print("Error downloading image:\(error)")
            }
        }
    }
    
    /*
     * add a call to remove the image from superview when the animation is stopped.
     */
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            let anImageView:UIImageView? = anim.value(forKey: "imageView") as? UIImageView
            if let imageView = anImageView {
                imageView.removeFromSuperview()
            }
        }
    }
    
    func calculateViewFrameForImageView()->CGRect {
        //calculate a random Point
        let maxX:UInt32 = UInt32(view.frame.size.width)
        let maxY:UInt32 = UInt32(view.frame.size.height)
        
        var aRandomPoint = CGPoint(x:Int(arc4random() % maxX),y:Int(arc4random() % maxY))
        
        //get the nav bar height + status bar height
        let navBarHeight = (self.navigationController?.navigationBar.frame.size.height)! + 20
    
        if (aRandomPoint.y < navBarHeight) {
            //displace it by navBarHeight
            aRandomPoint.y = aRandomPoint.y + navBarHeight
        }
        
        //get a random width and height
        let imageWidth:CGFloat = CGFloat(arc4random() % 200) + 50
        //make the imageWidth and height the same.
        let imageHeight:CGFloat = imageWidth
        
        
        var imageRect:CGRect = CGRect(x: aRandomPoint.x, y: aRandomPoint.y, width: imageWidth, height: imageHeight)
        let unionRect = self.view.frame.union(imageRect)
        
        //calculate if this imageRect is fully contained in the view
        if (unionRect != self.view.frame) {
            //which means that the position is need to be adjusted so it not placed offscreen
            let viewHeight = self.view.frame.size.height
            let viewWidth  = self.view.frame.size.width
            
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
