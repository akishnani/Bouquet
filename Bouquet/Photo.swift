//
//  Photo.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import Foundation
import UIKit

class Photo : NSObject, NSCoding {
    
    let title:String
    let remoteURL:URL
    let photoID:String
    let dateTaken:Date
    let width:Int
    let height:Int
    
    var frame:CGRect? //frame of animation layer
    var position:CGPoint? //center position of animation layer
    var duration:CFTimeInterval? //duration of animation
    var bIsPaused:Bool? //paused state of animation
    
    init(title:String, photoID:String, remoteURL:URL, dateTaken:Date, width:Int, height:Int) {
        self.title = title
        self.photoID = photoID
        self.remoteURL = remoteURL
        self.dateTaken = dateTaken
        self.width = width
        self.height = height
        self.frame = CGRect.zero
        self.position = CGPoint.zero
        self.duration = 10.0
        self.bIsPaused = false
    }
    
    func setPosition(position:CGPoint) {
        self.position = position
    }
    
    func setFrame(frame:CGRect) {
        self.frame = frame
    }
    
    func setDuration(aDuration:CFTimeInterval) {
        self.duration = aDuration
    }
    
    func isPaused(bIsPaused:Bool) {
        self.bIsPaused = bIsPaused
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(photoID, forKey: "photoID")
        aCoder.encode(remoteURL, forKey: "remoteURL")
        aCoder.encode(dateTaken, forKey: "dateTaken")
        aCoder.encode(width, forKey:"width")
        aCoder.encode(height, forKey:"height")
        aCoder.encode(frame, forKey: "frame")
        aCoder.encode(position, forKey: "position")
        aCoder.encode(duration,forKey:"duration")
        aCoder.encode(bIsPaused, forKey: "paused")
    }
    
    required init?(coder aDecoder: NSCoder) {
    
        self.title = aDecoder.decodeObject(forKey: "title") as! String
        self.photoID = aDecoder.decodeObject(forKey: "photoID") as! String
        self.remoteURL = aDecoder.decodeObject(forKey: "remoteURL") as! URL
        self.dateTaken = aDecoder.decodeObject(forKey: "dateTaken") as! Date
        self.width = aDecoder.decodeInteger(forKey: "width")
        self.height = aDecoder.decodeInteger(forKey: "height")
        self.frame = aDecoder.decodeObject(forKey: "frame") as? CGRect
        self.position = aDecoder.decodeObject(forKey: "position") as? CGPoint
        self.duration = aDecoder.decodeObject(forKey: "duration") as? CFTimeInterval
        self.bIsPaused = aDecoder.decodeObject(forKey: "paused") as? Bool
        
        super.init()
    }
}
