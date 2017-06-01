//
//  ViewController.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, CAAnimationDelegate {
    
    @IBOutlet weak var basketImageView: UIImageView!
    
    @IBOutlet var photosView: PhotosView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationController?.navigationBar.barTintColor = UIColor.black
        
        photosView.navController = self.navigationController
        photosView.basketImageView = basketImageView
        
     
        //register for the notification app becomes active
        NotificationCenter.default.addObserver(self, selector:#selector(PhotosViewController.appBecomesActive), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
        //register for the notification app will enter  background
        NotificationCenter.default.addObserver(self, selector:#selector(PhotosViewController.appDidEnterBackground), name:
            NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        //load any saved photos
        photosView.loadSavedPhotos()
    }
    
    
    func appBecomesActive() -> Void {
        photosView.loadSavedPhotos()
    }
    
    func appDidEnterBackground() -> Void {
        photosView.savePhotos()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("received memory warning")
    }
}
