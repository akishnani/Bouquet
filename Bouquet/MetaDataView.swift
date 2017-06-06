//
//  MetaDataView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 6/1/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class MetaDataView: UIView {
    
    //init the photo
    var photo:Photo

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        guard let context = UIGraphicsGetCurrentContext() else {return}

        context.addEllipse(in: rect)
        context.setFillColor(UIColor.yellow.cgColor)
        context.fillPath()
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokeEllipse(in: rect)
        
        
        //draw the string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        
        let radius = rect.size.height/2
        let fontSize = radius/5
        let font = UIFont(name: "AvenirNext-Regular", size: fontSize)
       
//        let metaDataInfo = "title:\(photo.title)\nwidth:\(photo.width)\nheight:\(photo.height)"
        let metaDataInfo = "width:\(photo.width)\nheight:\(photo.height)"

        let displayString = NSString(string: metaDataInfo)
        let textSize = displayString.size(attributes: [ NSFontAttributeName: font as Any])

        let centerX = (self.frame.size.width / 2.0) - ((textSize.width) / 2.0)
        let centerY = (self.frame.size.height / 2.0) - ((textSize.height) / 2.0)
        
        let textRect = CGRect(x: centerX, y: centerY, width: self.frame.size.width, height: self.frame.size.height)
        
        print("textRect::\(textRect)")

        displayString.draw(in: textRect, withAttributes: [ NSFontAttributeName: font as Any, NSForegroundColorAttributeName : UIColor.red , NSParagraphStyleAttributeName: paragraphStyle])
    }
 
    init(frame: CGRect, aPhoto:Photo) {
        
        self.photo = aPhoto

        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("inside meta data view deinit method")
    }
}
