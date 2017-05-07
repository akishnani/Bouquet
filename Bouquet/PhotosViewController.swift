//
//  ViewController.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var store:PhotoStore!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        store.searchPhotos {
            (photosResult) -> Void in
            switch (photosResult) {
                case let .success(photos):
                    print("Sucessfully found \(photos.count)")
                    if let firstPhoto = photos.first {
                        self.updateImageView(for: firstPhoto)
                }
                case let .failure(error):
                    print("Error searching photos \(error)")
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateImageView(for photo:Photo) {
        store.fetchImage(for: photo) {
            (imageResult) -> Void in
         
            switch imageResult {
            case let .success(image):
                self.imageView.image = image
            case let .failure(error):
                print("Error downloading image:\(error)")
            }
        }
    }
}

