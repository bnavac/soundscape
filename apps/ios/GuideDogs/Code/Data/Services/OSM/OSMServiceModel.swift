//
//  OSMServiceModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum HTTPStatusCode: Int {
    case unknown = 0
    case success = 200
    case notModified = 304
}

enum HTTPHeader: String {
    case ifNoneMatch = "If-None-Match"
    case eTag = "Etag"
}

enum ServiceError: Error {
    case jsonParseFailed
}

class OSMServiceModel: OSMServiceModelProtocol {
    /// Path to the tile server
    private static let path = "/tiles"
    ///Gets tile data from the webserver by passing in the coordintes (the vector tile), a queue of stuff to  do
    ///and some categories.
    /// - Parameters:
    ///    -tile: A VectorTile
    ///    -categories: A supercategory which helps to distinguish which object the user is looking at
    ///    -queue: A dispatch queue is a queue that allows for concurrency
    ///    -callback: Makes a call to a server which gets a status code
    func getTileDataWithQueue(tile: VectorTile, categories: SuperCategories, queue: DispatchQueue, callback: @escaping OSMServiceModelProtocol.TileDataLookupCallback) {
        let url = URL(string: "\(ServiceModel.servicesHostName)\(OSMServiceModel.path)/\(tile.zoom)/\(tile.x)/\(tile.y).json")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ServiceModel.requestTimeout)
        
        // Set the etag header
        do {
            try autoreleasepool {
                let cache = try RealmHelper.getCacheRealm()
                
                var etag = ""
                if let tiledata = cache.object(ofType: TileData.self, forPrimaryKey: tile.quadKey) {
                    etag = tiledata.etag
                }
                request.setValue(etag, forHTTPHeaderField: HTTPHeader.ifNoneMatch.rawValue)
            }
        } catch {
            callback(.unknown, nil, NSError(domain: ServiceModel.errorRealm, code: 0, userInfo: nil))
            return
        }
        
        // Set `App-Version` header
        request.setAppVersionHeader()
        
        // Some housekeeping: Show the network activity indicator on the status bar, and log the request
        ServiceModel.logNetworkRequest(request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let validationCallback = { (statusCode, newError) in
                callback(statusCode, nil, newError)
            }
            
            guard let (status, etag, json) = ServiceModel.validateJsonResponse(request: request, response: response, data: data, error: error, callback: validationCallback) else {
                return
            }
            
            queue.async {
                callback(status, TileData(withParsedData: json, quadkey: tile.quadKey, etag: etag, superCategories: categories), nil)
            }
        }
        
        task.resume()
    }
    /// 
    /// - Parameters:
    ///  -dyanmicURL: uses the url to make a request to the server
    /// - Returns:
    func getDynamicData(dynamicURL: String, callback: @escaping OSMServiceModelProtocol.DynamicDataLookupCallback) {
        guard !dynamicURL.isEmpty else {
            callback(.unknown, nil, NSError(domain: ServiceModel.errorDomain, code: 0, userInfo: nil))
            return
        }
        
        guard let url = URL(string: dynamicURL) else {
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ServiceModel.requestTimeout)
        request.setValue("plain/text", forHTTPHeaderField: "Accept")
        
        // Some housekeeping: Show the network activity indicator on the status bar, and log the request
        ServiceModel.logNetworkRequest(request)
        
        // Create the data task and start it
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let validationCallback = { (statusCode, newError) in
                callback(statusCode, nil, newError)
            }
            
            guard let status = ServiceModel.validateResponse(request: request, response: response, data: data, error: error, callback: validationCallback) else {
                return
            }
            
            DispatchQueue.main.async {
                callback(status, String.init(data: data!, encoding: .utf8), nil)
            }
        }
        
        task.resume()
    }
}
