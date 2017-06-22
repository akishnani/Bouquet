//
//  PhotoImageView.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/12/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotoImageView: UIImageView {
    
    //link to photo object
    var photo:Photo
    
    //duration which determine the velocity
    var duration:CFTimeInterval?

    public init(frame: CGRect, imageData:inout UIImage?, aPhoto:Photo) {
        
        //save the reference to the photo
        self.photo = aPhoto
        
        super.init(frame: frame)
                
        //make the image circular
        self.image = imageData?.circleMasked
        
        //release the old image after making it circular
        imageData = nil
        
        //make the user interaction enable
        self.isUserInteractionEnabled = true
        
//        //set a green border
//        self.layer.borderColor = UIColor.green.cgColor
//        self.layer.borderWidth = 1
    }
    
    
    deinit {
        print("inside the uiimageview deinitializer...")
        self.image = nil
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
