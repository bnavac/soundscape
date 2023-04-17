//
//  OSMServiceModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation


/// The `HTTPStatusCode` enumeration defines the HTTP status codes used by the service model.
enum HTTPStatusCode: Int {
    case unknown = 0
    case success = 200
    case notModified = 304
}


/// The `HTTPHeader` enumeration defines the HTTP headers used by the service model.
enum HTTPHeader: String {
    case ifNoneMatch = "If-None-Match"
    case eTag = "Etag"
}

/// The `ServiceError` enumeration defines the errors that may be thrown by the service model.
enum ServiceError: Error {
    case jsonParseFailed
}

/// The `OSMServiceModel` class provides methods for retrieving data from a tile server and a dynamic data source.
class OSMServiceModel: OSMServiceModelProtocol {
    /// Path to the tile server
    private static let path = "/tiles"

    
    /// Returns tile data for the given `tile` object and `categories` object asynchronously.
    /// - Parameters:
    ///    - tile: The `VectorTile` object for which to retrieve data.
    ///    - categories: The `SuperCategories` object containing the categories for which to retrieve data.
    ///    - queue: The `DispatchQueue` object on which to execute the `callback` function.
    ///    - callback: The function to call when the data is retrieved. The function takes three parameters: the HTTP status code of the response, the retrieved `TileData` object, and any error that occurred during retrieval.
    func getTileDataWithQueue(tile: VectorTile, categories: SuperCategories, queue: DispatchQueue, callback: @escaping OSMServiceModelProtocol.TileDataLookupCallback) {
        let url = URL(string: "\(ServiceModel.servicesHostName)/\(tile.zoom)/\(tile.x)/\(tile.y)")!
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
    
    /// Returns dynamic data for the given URL asynchronously.
    /// - Parameters:
    ///   - dynamicURL: The URL from which to retrieve the dynamic data.
    ///   - callback: The function to call when the data is retrieved. The function takes three parameters: the HTTP status code of the response, the retrieved data as a `String`, and any error that occurred during retrieval.
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
