//
//  NetworkClient.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// An error type that represents the failure to return data from the network request.
enum NetworkError: Error {
    case noDataReturned
}

/// A struct representing the response from the remote server.
struct NetworkResponse {
    /// The HTTP response header fields.
    var allHeaderFields: [AnyHashable: Any]
    /// The HTTP response status code.
    var statusCode: HTTPStatusCode
    
    /// A static property representing an empty `NetworkResponse`.
    static var empty: NetworkResponse {
        return .init(allHeaderFields: [:], statusCode: .unknown)
    }
}

/// The `NetworkClient` protocol defines a method to request data from a remote server.
///
/// Conforming types should implement the `requestData` method which takes a `URLRequest` as input and returns a tuple of `Data` and `NetworkResponse`.
protocol NetworkClient {
    /// Requests data from the remote server using the provided `URLRequest`.
    /// - Parameters:
    ///   - request: The request to send to the remote server.
    /// - Returns: A tuple containing the `Data` returned by the server and the `NetworkResponse`.
    /// - Throws: An error of type `NetworkError.noDataReturned` if no data is returned by the server.
    func requestData(_ request: URLRequest) async throws -> (Data, NetworkResponse)
}

/// An implementation of the `NetworkClient` protocol using `URLSession`.
extension URLSession: NetworkClient {
    /// Requests data from the remote server using the provided `URLRequest` asynchronously.
    /// - Parameters:
    ///   - request: The request to send to the remote server.
    /// - Returns: A tuple containing the `Data` returned by the server and the `NetworkResponse`.
    /// - Throws: An error of type `NetworkError.noDataReturned` if no data is returned by the server.
    func requestData(_ request: URLRequest) async throws -> (Data, NetworkResponse) {
        request.log()
        
        if #available(iOS 15.0, *) {
            let (data, response) = try await data(for: request)
            response.log(request: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (data, NetworkResponse(allHeaderFields: [:], statusCode: .unknown))
            }
            
            guard let status = HTTPStatusCode(rawValue: httpResponse.statusCode) else {
                return (data, NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: .unknown))
            }
            
            let netResponse = NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: status)
            return (data, netResponse)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task: URLSessionDataTask = dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        continuation.resume(with: .failure(error))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(with: .failure(NetworkError.noDataReturned))
                        return
                    }
                    
                    response?.log(request: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, let status = HTTPStatusCode(rawValue: httpResponse.statusCode) else {
                        continuation.resume(with: .success((data, .empty)))
                        return
                    }
                    
                    let response = NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: status)
                    continuation.resume(with: .success((data, response)))
                }
                
                task.resume()
            }
        }
    }
}

extension URLRequest {
    /// Logs the HTTP method and URL of the `URLRequest`.
    func log() {
        guard let method = httpMethod?.prefix(3) else {
            return
        }
        
        GDLogVerbose(.network, "Request (\(method)) \(url?.absoluteString ?? "unknown")")
    }
}

extension URLResponse {
    /// Logs the HTTP method, response status code, and URL of the `URLResponse`.
    ///
    /// - Parameters:
    ///   - request: The original `URLRequest` that generated the response.
    func log(request: URLRequest) {
        let responseStatus: HTTPStatusCode
        if let res = self as? HTTPURLResponse {
            responseStatus = HTTPStatusCode(rawValue: res.statusCode) ?? .unknown
        } else {
            responseStatus = .unknown
        }
        
        guard let method = request.httpMethod?.prefix(3) else {
            return
        }
        
        GDLogVerbose(.network, "Response (\(method)) \(responseStatus.rawValue) '\(request.url?.absoluteString ?? "unknown")'")
    }
}
