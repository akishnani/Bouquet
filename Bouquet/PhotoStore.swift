//
//  PhotoStore.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import Foundation

enum PhotoResult {
    case success([Photo])
    case failure(Error)
}

class PhotoStore {
 
    private let session:URLSession = {
       let config = URLSessionConfiguration.default
       return URLSession(configuration: config)
    }()
    
    func searchPhotos() {
        let url = FlickrAPI.searchFlickrURL
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            if let jsonData = data {

                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    print (jsonObject)
                } catch let error {
                    print("Error creating json object:\(error)");
                }
            } else if let requestError = error {
                print("Error searching photos:\(requestError)")
            } else {
                print("Unexpected error with the request")
            }
        }
        task.resume()
    }
}
