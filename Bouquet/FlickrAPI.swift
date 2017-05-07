//
//  FlickrAPI.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import Foundation


enum FlickrError: Error {
    
}

enum Method:String {
    case searchPhotos = "flickr.photos.search"
}

struct FlickrAPI {
    
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "b7067bfca4c0d09250593e7c6d491e53"
    

    private static func flickrURL(method:Method, parameters:[String:String]?) -> URL {
     
        var components = URLComponents(string: baseURLString)!
        
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            "method": method.rawValue,
            "format":"json",
            "nojsoncallback": "1",
            "api_key" : apiKey,
            "text" : "flower",
            "per_page" : "5"
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name:key, value:value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name:key, value:value)
                queryItems.append(item)
            }
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    static var searchFlickrURL : URL {
        return flickrURL(method: .searchPhotos,
                         parameters: ["extras" : "url_h, date_taken"])
    }
}
