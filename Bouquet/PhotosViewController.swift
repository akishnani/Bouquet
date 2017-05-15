//
//  ViewController.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

     var store:PhotoStore!
     //var animator:UIDynamicAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //self.animator = UIDynamicAnimator(referenceView: self.view)
        
        store.searchPhotos {
            [weak self](photosResult) -> Void in
            switch (photosResult) {
                case let .success(photos):
                    print("Sucessfully found \(photos.count)")
                
                    //iterate through the list and randomly place images on the screeen
                    for aPhoto in photos {
                        self?.fetchImage(aPhoto: aPhoto)
                    }
                
                case let .failure(error):
                    print("Error searching photos \(error)")
                }
        }
    }
    
    
    func fetchImage(aPhoto:Photo) {
        store.fetchImage(for: aPhoto) {
            (imageResult) -> Void in
            
            switch imageResult {
            case let .success(image):
                aPhoto.imageData = image
                
                var aRandomPoint = CGPoint.random()
                
                //get the nav bar height
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
                
                //create a UIImageview object from the data loaded from the internet (flickrAPI)
                let anImageView = PhotoImageView(frame: imageRect)
                anImageView.image = image
                anImageView.layer.cornerRadius = anImageView.frame.size.width / 2
                anImageView.layer.masksToBounds = true
                
                //add an explicit animation
                let toX = aRandomPoint.x
                let toY = self.view.frame.size.height + imageRect.size.height/2
                let toPoint = CGPoint(x: toX, y: toY)
                let randomDuration:CFTimeInterval = CFTimeInterval(arc4random() % 5) + 10
                
                let movement = CABasicAnimation(keyPath: "position")
                movement.fromValue = NSValue(cgPoint: aRandomPoint)
                movement.toValue = NSValue(cgPoint: toPoint)
                movement.duration = randomDuration
                anImageView.layer.position = toPoint
                anImageView.layer.add(movement, forKey: "move")

                //add it to the subview
                self.view.addSubview(anImageView)
                
                

                //add the gravity , sliding down behavior
                
                
                /*let aUIGravityBehavior:UIGravityBehavior = UIGravityBehavior(items: [aImageView])
                self.animator.addBehavior(aUIGravityBehavior)
                
                let aDyanmicItemBehavior:UIDynamicItemBehavior = UIDynamicItemBehavior(items: [aImageView])
                aDyanmicItemBehavior.resistance = 40.0
                self.animator.addBehavior(aDyanmicItemBehavior)
                
                
                let aCollisionBehavior:UICollisionBehavior = UICollisionBehavior(items: [aImageView])
                aCollisionBehavior.translatesReferenceBoundsIntoBoundary = true
                self.animator.addBehavior(aCollisionBehavior)*/
                
            case let .failure(error):
                print("Error downloading image:\(error)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension CGPoint {
    
    fileprivate static func random()->CGPoint {
        
        let screenRect:CGRect = UIScreen.main.bounds
        let maxX:UInt32 = UInt32(screenRect.width)
        let maxY:UInt32 = UInt32(screenRect.height)
        
        return CGPoint(x:Int(arc4random() % maxX),y:Int(arc4random() % maxY))
    }
}
