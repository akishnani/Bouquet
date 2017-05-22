//
//  PhotoImageView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/12/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotoImageView: UIImageView,CAAnimationDelegate {
    
    //default paused is false
    var bPaused:Bool = false

    //default isDragging is false
    var bIsDragging:Bool = false
    
    //default isPinching is false
    var bIsPinching = false
    
    //display link timer which updates on each screen refresh cycle
    fileprivate var timer: CADisplayLink?
    
    //store the state of previous animation
    var aBasicAnimation:CABasicAnimation? = nil

    public init(frame: CGRect, imageData:UIImage) {
        super.init(frame: frame)
        
        //make the image circular
        self.image = imageData.circleMasked
        
        //make the user interaction enable
        self.isUserInteractionEnabled = true
        
        //add a tap gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoImageView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(tapRecognizer)
        
        //add a pan gesture
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PhotoImageView.drag(_:)))
        addGestureRecognizer(panRecognizer)
        
        //add a pinch recognizer
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(PhotoImageView.scalePiece(_:)))
        addGestureRecognizer(pinchRecognizer)
        
        //add a timer to adjust the imageRect
        addDisplayLink()
    }
    
    fileprivate func addDisplayLink() {
        timer = CADisplayLink(target: self, selector: #selector(self.update(timer:)))
        timer?.add(to: .main, forMode: .defaultRunLoopMode)
        timer?.add(to: .main, forMode: .UITrackingRunLoopMode)
    }
    
    /*
     * function is being called on each screen update in order to update the imagerect (frame) to the 
     * presentation layer frame. this is done for gesture recognizer to function inspite of the animation
     * (example) tapgesturereconsizer to pause/resume animation. Please see the stackoverflow post
     * http://stackoverflow.com/questions/12287267/ios-uiimageview-tap-gesture-not-working-during-animation
     * I think calling this function is reverse the effect of dragging and the image snaps back into original
     * position - not sure how to architect this function....if you comment the below code the gesture 
     * recongizers don't function.
     */
    @objc func update(timer: Timer) {
        
        if (!bIsDragging && !bIsPinching) {
            let viewLocation:CGRect = (self.layer.presentation()?.frame)!
            self.frame = CGRect(x: viewLocation.origin.x, y: viewLocation.origin.y, width: viewLocation.size.width, height: viewLocation.size.height)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func tap(_ gestureRecognizer:UIGestureRecognizer) {
        
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
            
            //readd the animation which was removed temporarily
            self.reAddAnimation()
            
            return;
        }
        
        if (gestureRecognizer.state == .began) {
            //remove the animation temporarily since we are changing the position in response to pan gesture
            self.layer.removeAnimation(forKey: "move")
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
            self.reAddAnimation()
            
            return;
        }

        if (gestureRecognizer.state == .began) {
            //remove the animation temporarily since we are changing the position in response to pinch gesture
            self.layer.removeAnimation(forKey: "move")
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
    
    /**
    * re-add animation which was removed on drag
    */
    func reAddAnimation() {
        //readd the animation
        //add an explicit animation
        let toX = self.center.x
        let toY = (self.superview?.frame.size.height)! + self.frame.size.height/2
        let toPoint = CGPoint(x: toX, y: toY)
        let randomDuration:CFTimeInterval = CFTimeInterval(arc4random() % 5) + 5
        
        let movement = CABasicAnimation(keyPath: "position")
        movement.fromValue = NSValue(cgPoint: self.center)
        movement.toValue = NSValue(cgPoint: toPoint)
        movement.duration = randomDuration
        movement.delegate = self
        
        self.layer.position = toPoint
        self.layer.add(movement, forKey: "move")
    }
    
    
    /*
    * pause animation
    */
    func pauseAnimation() {
        let pausedTime:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        self.layer.speed = 0
        self.layer.timeOffset = pausedTime
    }
    
    /*
    * resume animation
    */
    func resumeAnimation() {
        let pausedTime:CFTimeInterval = layer.timeOffset
        self.layer.speed = 1.0
        self.layer.timeOffset = 0.0
        self.layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        self.layer.beginTime = timeSincePause
    }
    
    /*
     * add a call to remove the image from superview when the animation is stopped.
     */
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            self.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
 * http://stackoverflow.com/questions/29046571/cut-a-uiimage-into-a-circle-swiftios
 */

extension UIImage {
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
