//
//  FlickrAPI.swift
//  Bouquet
//
//  Created by AMIT KISHNANI on 5/5/17.
//  Copyright © 2017 ucsc. All rights reserved.
//

import Foundation


enum FlickrError: Error {
    case invalidJSONData
}

enum Method:String {
    case searchPhotos = "flickr.photos.search"
}

struct FlickrAPI {
    
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "b7067bfca4c0d09250593e7c6d491e53" //api key generated corresponding to Bouquet app
    private static var pageNo:Int = 0

    private static let dateFormatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static func flickrURL(method:Method, parameters:[String:String]?) -> URL {
     
        var components = URLComponents(string: baseURLString)!
        
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            "method": method.rawValue,
            "format":"json",
            "nojsoncallback": "1",
            "api_key" : apiKey,
            "text" : "flower",
            "per_page" : "25"
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
        pageNo += 1
        print("search Flickr API page no:\(pageNo)")
        return flickrURL(method: .searchPhotos,
                         parameters: ["extras" : "url_h, date_taken",
                                      "page": String(pageNo)])
    }
    
    static func photos(fromJSON data:Data) -> PhotosResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data,
                                                          options: [])
//          print(jsonObject)
            
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let photos = jsonDictionary["photos"] as? [String:Any],
                let photoArray = photos["photo"] as? [[String:Any]] else {
                    return .failure(FlickrError.invalidJSONData)
            }
            
            var finalPhotos = [Photo]()
            for photoJSON in photoArray {
                if let photo = photo(fromJSON: photoJSON) {
                    finalPhotos.append(photo)
                }
            }
            
            if (finalPhotos.isEmpty && !photoArray.isEmpty) {
                return .failure(FlickrError.invalidJSONData)
            }
            
            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
    }
    
    private static func photo(fromJSON json:[String:Any]) -> Photo? {
        
        //special handling for photoWidth and photoHeight since sometimes it is getting
        //returned as NSString and other times as NSNumber - so this below handles both
        //cases
        var photoHeight:Int=0
        var photoWidth:Int=0
        
        for (jsonKey,jsonValue) in json {
            switch jsonKey {
            case "height_h":
                if let aJsonValue=jsonValue as? NSNumber {
                    photoHeight = Int(aJsonValue)
                } else if let aJsonValue=jsonValue as? String {
                    photoHeight = Int(aJsonValue)!
                }
            case "width_h":
                if let aJsonValue=jsonValue as? NSNumber {
                    photoWidth = Int(aJsonValue)
                } else if let aJsonValue=jsonValue as? String {
                    photoWidth = Int(aJsonValue)!
                }
            default :
                break
            }
        }
        
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else {
                //don't have enough information to construct the photo
                return nil
        }
    
        return Photo(title: title, photoID: photoID, remoteURL: url, dateTaken: dateTaken, width:photoWidth,height:photoHeight);
     }
}
