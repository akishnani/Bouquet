//
//  ContainerView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 6/2/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class ContainerView: UIView, CAAnimationDelegate {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    //init the photo
    var photo:Photo
    
    //default paused is false
    var bPaused:Bool = false
    
    //default isDragging is false
    var bIsDragging:Bool = false
    
    //default isPinching is false
    var bIsPinching = false
    
    //if the user has double tapped the container view
    var bIsDoubleTapped = false
    
    //duration which determine the velocity
    var duration:CFTimeInterval
    
    //favorites basket view
    var basketImageView:UIImageView? = nil
    
    //double tap notification
    let doubleTapNotificationName = Notification.Name("doubleTapNotification")
    
    //handle animation finished notification
    let animationFinishedNotification = Notification.Name("animationFinishedNotification")
    
    //adding to favorite basket notification
    let addToFavoritesNotification = Notification.Name("addToFavoritesNotification")
    
    
    //display link timer which updates on each screen refresh cycle
    fileprivate var timer: CADisplayLink?

    init(frame: CGRect,aPhoto:Photo, duration:CFTimeInterval) {
        
        self.photo = aPhoto
        
        self.duration = duration
        
        super.init(frame: frame)
        
        //add a double tap gesture
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContainerView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        //add a tap gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContainerView.tap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        //add a pan gesture
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerView.drag(_:)))
        addGestureRecognizer(panRecognizer)
        
        //add a pinch recognizer
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ContainerView.scalePiece(_:)))
        addGestureRecognizer(pinchRecognizer)
        
        //add a timer to adjust the imageRect
        addDisplayLink()
    }
    
    
    fileprivate func addDisplayLink() {
        timer = CADisplayLink(target: self, selector: #selector(self.update(timer:)))
        timer?.add(to: .main, forMode: .defaultRunLoopMode)
        timer?.add(to: .main, forMode: .UITrackingRunLoopMode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("inside the deinit method of Collection View")
    }
    
    /*
     * function is being called on each screen update in order to update the imagerect (frame) to the
     * presentation layer frame. this is done for gesture recognizer to function inspite of the animation
     * (example) tapgesturereconsizer to pause/resume animation. Please see the stackoverflow post
     * http://stackoverflow.com/questions/12287267/ios-uiimageview-tap-gesture-not-working-during-animation
     *
     */
    @objc func update(timer: Timer) {
        
        if (!bIsDragging && !bIsPinching) {
            if let presentationLayer = self.layer.presentation() {
                let viewLocation:CGRect = presentationLayer.frame
                self.frame = CGRect(x: viewLocation.origin.x, y: viewLocation.origin.y, width: viewLocation.size.width, height: viewLocation.size.height)
            }
        }
    }
    
    func doubleTap(_ gestureRecognizer:UIGestureRecognizer) {
        //send a notification so that PhotosView can respond
        print("inside a double tap")
        
        if (self.subviews.count > 0) {
            bIsDoubleTapped = true
            let aSubView = subviews[0]
            NotificationCenter.default.post(name: doubleTapNotificationName, object: nil,
                                            userInfo:["subView":aSubView, "gestureRecognizer":gestureRecognizer])
        }
    }
    
    func tap(_ gestureRecognizer:UIGestureRecognizer) {
        
        
        if (bIsDoubleTapped) {
            bIsDoubleTapped = false
            return
        }
        
        print("inside a single tap")

        if (!bPaused) {
            //pause the animation
            self.pauseAnimation()
            
            bPaused = true
        } else {
            //resume the paused animation on tap
            self.resumeAnimation()
            bPaused = false
        }
    }
    
    
    func pauseAnimation() {
        self.layer.removeAllAnimations()
    }
    
    func resumeAnimation() {
        self.reAddAnimation()
    }
    
    /**
     * re-add animation which was removed on drag
     */
    func reAddAnimation() {
        //readd the animation
        let toX = self.center.x
        let toY = (self.superview?.frame.size.height)! + self.frame.size.height
        let toPoint = CGPoint(x: toX, y: toY)
        let randomDuration:CFTimeInterval = self.duration
        
        let movement = CABasicAnimation(keyPath: "position")
        movement.fromValue = NSValue(cgPoint: self.center)
        movement.toValue = NSValue(cgPoint: toPoint)
        movement.duration = randomDuration
        movement.delegate = self
        
        self.layer.position = toPoint
        self.layer.fillMode = kCAFillModeForwards
        self.layer.add(movement, forKey: "move")
    }
    
    
    
    func drag(_ gestureRecognizer:UIPanGestureRecognizer) {
        
        
        if (gestureRecognizer.state == .ended)
        {
            print("drag call ended")
            
            bIsDragging = false
            
            let newCenter:CGPoint = CGPoint(x:
                self.center.x + self.transform.tx, y:
                self.center.y + self.transform.ty)
            self.center = newCenter
            
            var theTransform:CGAffineTransform  = self.transform
            theTransform.tx = 0.0
            theTransform.ty = 0.0
            self.transform = theTransform
            
            //drag ended check if it was over the basket
            let basketRect:CGRect = (basketImageView?.frame)!
            let viewPosition = self.layer.position
            if (basketRect.contains(viewPosition)) {
                print("put item in basket")
                animationCompleted()
                photo.setFrame(frame: self.frame)
                //send a notification when a flower is added to basket view
                NotificationCenter.default.post(name: addToFavoritesNotification, object: nil,
                                                userInfo:["photo":photo])
                
                return
            }
            
            //readd the animation which was removed temporarily
            if (!bPaused) {
                self.reAddAnimation()
            }
            return;
        }
        
        if (gestureRecognizer.state == .began) {
            //remove the animation temporarily since we are changing the position in response to pan gesture
            self.layer.removeAllAnimations()
        }
        
        bIsDragging = true;
        let translation:CGPoint = gestureRecognizer.translation(in: self.superview)
        var theTransform:CGAffineTransform = self.transform;
        theTransform.tx = translation.x
        theTransform.ty = translation.y
        self.transform = theTransform
    }

    
    
    func scalePiece(_ gestureRecognizer : UIPinchGestureRecognizer) {
        
        if (gestureRecognizer.state == .ended)
        {
            print("pinch gesture call ended")
            
            bIsPinching = false
            
            //readd the animation which was removed temporarily
            if (!bPaused) {
                self.reAddAnimation()
            }
            
            return;
        }
        
        bIsPinching = true
        if (gestureRecognizer.state == .began) {
            //remove the animation temporarily since we are changing the position in response to pinch gesture
            self.layer.removeAllAnimations()
        }
        
        // Scale the view by the current scale factor.
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            gestureRecognizer.view?.transform =
                (gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale,
                                                            y: gestureRecognizer.scale))!
            // Set the scale factor to 1.0 to avoid exponential growth
            gestureRecognizer.scale = 1.0
        }
    }
    
    
    
    /*
     * add a call to remove the image from superview when the animation is stopped.
     */
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            animationCompleted()
        }
    }
    
    func animationCompleted() {
        if (self.subviews.count > 0) {
            let aSubView = subviews[0]
            NotificationCenter.default.post(name: animationFinishedNotification, object: nil,
                                            userInfo:["subView":aSubView])
        }
        
        for aSubview in self.subviews {
            if let anImageView = aSubview as? PhotoImageView {
                anImageView.removeFromSuperview()
                anImageView.image = nil
            }
            
            if let aMetaDataView = aSubview as? MetaDataView {
                aMetaDataView.removeFromSuperview()
            }
        }
        
        self.layer.removeAllAnimations()
        self.removeFromSuperview()        
    }
    
    
}
