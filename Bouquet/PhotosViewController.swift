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
        
        //set the background to light blue color : 173, 216, 230
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 173.0/255, green: 216.0/255.0, blue: 230.0/255.0, alpha: 1.0)

        self.view.backgroundColor = UIColor(red: 173.0/255, green: 216.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        
        photosView.navController = self.navigationController
        photosView.basketImageView = basketImageView
        
        let bouquetTitle = NSLocalizedString("Bouquet", comment: "title for normal bouquet mode")
        self.navigationController?.navigationBar.topItem?.title = bouquetTitle
     
        //register for the notification app becomes active
        NotificationCenter.default.addObserver(self, selector:#selector(PhotosViewController.appBecomesActive), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
        //register for the notification app will enter  background
        NotificationCenter.default.addObserver(self, selector:#selector(PhotosViewController.appDidEnterBackground), name:
            NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        
        //register for orientation change method
        NotificationCenter.default.addObserver(self, selector: #selector(PhotosViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        
        
        //load any saved photos between launch sessions and could be internet is not available
        //we want all the photos even the ones which are not displayed when we were terminated
        //last time.
        photosView.loadSavedPhotos(bActivePhotos: false)
        
        
    }
    
    func rotated() {
        if UIDevice.current.orientation.isLandscape {
            photosView.handleOrientationChanges(orientation: "Landscape")
        } else {
            photosView.handleOrientationChanges(orientation: "Portrait")
        }
    }
    
    
    func appBecomesActive() -> Void {
        photosView.loadSavedPhotos(bActivePhotos: true)
    }
    
    func appDidEnterBackground() -> Void {
        photosView.savePhotos(bActivePhotos:true) //true to save only active photos on the screen
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        photosView.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        photosView.viewWillDisappear()
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("PhotosViewController::received memory warning")
    }
}
