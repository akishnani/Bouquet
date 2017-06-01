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
    var frame:CGRect?
    var position:CGPoint?
    var duration:CFTimeInterval?
    
    init(title:String, photoID:String, remoteURL:URL, dateTaken:Date) {
        self.title = title
        self.photoID = photoID
        self.remoteURL = remoteURL
        self.dateTaken = dateTaken
        self.frame = CGRect.zero
        self.position = CGPoint.zero
        self.duration = 10.0
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
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(photoID, forKey: "photoID")
        aCoder.encode(remoteURL, forKey: "remoteURL")
        aCoder.encode(dateTaken, forKey: "dateTaken")
        aCoder.encode(frame, forKey: "frame")
        aCoder.encode(position, forKey: "position")
        aCoder.encode(duration,forKey:"duration")

    }
    
    required init?(coder aDecoder: NSCoder) {
    
        self.title = aDecoder.decodeObject(forKey: "title") as! String
        self.photoID = aDecoder.decodeObject(forKey: "photoID") as! String
        self.remoteURL = aDecoder.decodeObject(forKey: "remoteURL") as! URL
        self.dateTaken = aDecoder.decodeObject(forKey: "dateTaken") as! Date
        self.frame = aDecoder.decodeObject(forKey: "frame") as? CGRect
        self.position = aDecoder.decodeObject(forKey: "position") as? CGPoint
        self.duration = aDecoder.decodeObject(forKey: "duration") as? CFTimeInterval
        
        super.init()
    }
}
