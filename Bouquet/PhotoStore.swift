//
//  PhotoStore.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import Foundation
import UIKit

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}


enum PhotoLoadingError: Error {
    case failedToLoadDataError
}


enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

class PhotoStore {
    
    //this is photo dictionary saved between launches
    //it helps with usecase when the the internet is offline we can still load the photos
    var allPhotos = [String:Photo]()
    
    //list of photos active on the screen between suspend (going into background and active state)
    var activePhotos = [String:Photo]()
    
    let imageStore = ImageStore()
    
    //creating a singleton class for Photostore
    static let sharedInstance = PhotoStore()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
    }
 
    private let session:URLSession = {
       let config = URLSessionConfiguration.default
       return URLSession(configuration: config)
    }()
    
    //path to photos.archive
    private let photoArchiveURL:URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        return documentDirectory.appendingPathComponent("photos.archive")
    } ()

    
    //path to activephotos.archive
    private let activePhotoArchiveURL:URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        return documentDirectory.appendingPathComponent("activephotos.archive")
    } ()
    
    private func processPhotosRequest(data:Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return FlickrAPI.photos(fromJSON: jsonData)
    }

    func searchPhotos(completion:@escaping (PhotosResult) -> Void) {
        let url = FlickrAPI.searchFlickrURL
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            let result = self.processPhotosRequest(data: data, error: error)
            
            if case let .success(photos) = result {
                //iterate through the list and add them to photo dictionary
                for aPhoto in photos {
                    self.allPhotos.updateValue(aPhoto, forKey: aPhoto.photoID)
                }
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }

    
    func loadActivePhotos() -> [Photo]? {
        if let archivedPhotos = NSKeyedUnarchiver.unarchiveObject(withFile: activePhotoArchiveURL.path) as? [String:Photo] {
            
            //loaded photo count
            print("load  active \(archivedPhotos.count) photos between foreground and background state " )
            
            for (key, value) in archivedPhotos {
                self.activePhotos.updateValue(value, forKey: key)
            }
            
            var arrPhotos = [Photo]()
            for (_, value) in self.activePhotos {
                arrPhotos.append(value)
            }
            return arrPhotos
        }
        return nil
    }
    
    func loadPhotos() -> [Photo]? {
        if let archivedPhotos = NSKeyedUnarchiver.unarchiveObject(withFile: photoArchiveURL.path) as? [String:Photo] {
            
            //loaded photo count
            print("load \(archivedPhotos.count) photos between launches" )
            
            for (key, value) in archivedPhotos {
                self.allPhotos.updateValue(value, forKey: key)
            }
                        
            var arrPhotos = [Photo]()
            for (_, value) in self.allPhotos {
                arrPhotos.append(value)
            }
            
            return arrPhotos
         }
         return nil
    }
    
    func savePhotos() -> Bool {
        print("saving \(self.allPhotos.count) photos to \(photoArchiveURL.path)")
        return NSKeyedArchiver.archiveRootObject(self.allPhotos, toFile: photoArchiveURL.path)
    }
    
    func saveActivePhotos() -> Bool {
        print("saving \(self.activePhotos.count) active photos to \(activePhotoArchiveURL.path)")
        return NSKeyedArchiver.archiveRootObject(self.activePhotos, toFile: activePhotoArchiveURL.path)
    }
    
    func removeAllPhotos() {
        //remove all photo key-value pairs
        self.allPhotos.removeAll()
    }
    
    func removeAllActivePhotos() {
        //remove all active photos list
        self.activePhotos.removeAll()
    }
    
    func fetchImage(for photo:Photo , completion:@escaping (ImageResult) -> Void) {
        
        let photoKey = photo.photoID
        
        ///load the image from the image store (cache)
        if let image = imageStore.image(forKey: photo.photoID) {
            print("found key:\(photoKey) in image store")
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        let photoURL = photo.remoteURL
        var request = URLRequest(url: photoURL)
        
        //caching policy to load from local cache - else go back to original source (remote source)
        request.cachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error)
            
            if case let .success(image) = result {
                //save the image to imagestore (cache)
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }

    private func processImageRequest(data:Data? , error:Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data:imageData) else {
     
                if data == nil {
                    return .failure(error!)
                } else  {
                    return .failure(PhotoError.imageCreationError)
                }
            }
        return .success(image)
    }
 
    
}
