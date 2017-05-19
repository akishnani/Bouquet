//
//  PhotoImageView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/12/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotoImageView: UIImageView {
    
    //default paused is false
    var bPaused:Bool = false

    //default isDragging is false
    var bIsDragging:Bool = false
    
    //display link timer which updates on each screen refresh cycle
    fileprivate var timer: CADisplayLink?

    //This variable will keep track of the last position of a user's touch
    var previousLocation:CGPoint = CGPoint.zero

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        //add a tap gesture
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoImageView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(tapRecognizer)
        
        //add a pan gesture
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PhotoImageView.drag(_:)))
        addGestureRecognizer(panRecognizer)
        
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
        
        if (!bIsDragging) {
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
            let pausedTime:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
            self.layer.speed = 0
            self.layer.timeOffset = pausedTime
            bPaused = true
        } else {
            //resume the paused animation on tap
            let pausedTime:CFTimeInterval = layer.timeOffset
            self.layer.speed = 1.0
            self.layer.timeOffset = 0.0
            self.layer.beginTime = 0.0
            let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            self.layer.beginTime = timeSincePause
            bPaused = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Remember original location
        previousLocation = self.center
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

            return;
        }
        
        bIsDragging = true;
        let translation:CGPoint = gestureRecognizer.translation(in: self.superview)
        var theTransform:CGAffineTransform = self.transform;
        theTransform.tx = translation.x
        theTransform.ty = translation.y
        self.transform = theTransform
     
        /*
        let translation:CGPoint = uigr.translation(in: self.superview)
        print("before center:\(self.center), translation:\(translation)")
        self.center = CGPoint(x: previousLocation.x + translation.x, y: previousLocation.y + translation.y)
        print("after center:\(self.center), previousLocation:\(previousLocation), translation:\(translation)")*/
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
