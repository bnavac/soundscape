//
//  Device.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum DeviceError: Error {
    /// Indicates that the device's firmware needs to be updated before it can be connected.
    case unsupportedFirmwareVersion
    /// Indicates that a connection error had occurred.
    case failedConnection
    /// Indicates that a device becomes unavailable.
    case unavailable
    /// Indicates that a user canceled the connection attempt.
    case userCancelled
}

/// The `DeviceDelegate` protocol defines the interface for receiving events related to a device's connection state.
/// Use this protocol to receive notifications about a device's connection state, such as when it connects or disconnects.
protocol DeviceDelegate: AnyObject {
    /// Called when a device connects to the app.
    /// - Parameter device: The device that has connected.
    func didConnectDevice(_ device: Device)
    
    /// Called when a device fails to connect to the app.
    /// - Parameters:
    ///   - device: The device that failed to connect.
    ///   - error: The error that caused the connection to fail.
    func didFailToConnectDevice(_ device: Device, error: DeviceError)
    
    /// Called when a device disconnects from the app.
    /// - Parameter device: The device that has disconnected.
    func didDisconnectDevice(_ device: Device)
}

typealias DeviceCompletionHandler = (Result<Device, DeviceError>) -> Void

/// The type of a device that can be used in the app.
/// Use this enum to specify the type of device that is being used in the app.
enum DeviceType: String, Codable, CaseIterable {
    /// An Apple device, such as an iPhone or iPad.
    case apple
}

extension DeviceType {
    
    // When applicable, define a reachability protocol for
    // supported devices.
    //
    // This protocol will be used to prompt the user to enable
    // head tracking when the device is reachable but not
    // connected in Soundscape
    var reachability: DeviceReachability? {
        switch self {
        case .apple: return HeadphoneMotionManagerReachabilityWrapper()
        }
    }
    
}

/// The `Device` protocol defines the interface for interacting with a device.
/// Implement this protocol to create a custom device for use in the Soundscape app.
protocol Device: AnyObject {
    /// The unique identifier of the device.
    var id: UUID { get }
    /// The name of the device.
    var name: String { get }
    /// The model of the device.
    var model: String { get }
    /// The type of the device.
    var type: DeviceType { get }
    /// Whether the device is currently connected.
    var isConnected: Bool { get }
    /// Whether the device is being connected for the first time.
    var isFirstConnection: Bool { get }
    
    /// The device delegate that receives connection events for this device.
    var deviceDelegate: DeviceDelegate? { get set }
    
    /// Sets up the device for use in the app.
    /// Call this method to initialize the device and any necessary resources before connecting it.
    /// - Parameter callback: A closure to be called when the setup is complete.
    static func setupDevice(callback: @escaping DeviceCompletionHandler)

    /// Connects the device to the app.
    /// Call this method to establish a connection with the device.
    func connect()
    
    /// Disconnects the device from the app.
    /// Call this method to end the connection with the device.
    func disconnect()
}

extension Device {
    /// A dictionary representation of the device.
    /// This property returns a dictionary that contains the device's ID, name, and type.
    var dictionaryRepresentation: [String: Any] {
        return ["id": id.uuidString,
                "name": name,
                "type": type.rawValue]
    }
}
