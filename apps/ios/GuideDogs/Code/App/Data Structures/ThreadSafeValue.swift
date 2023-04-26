//
//  ThreadSafeValue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// This class wraps the access methods for the given value in a thread-safe, concurrent queue. Read access
/// is done synchronously. Write access is done asynchronously with a barrier.
///
/// Example usage:
///
/// ```
/// // Create a new ThreadSafeValue instance with an initial value of 0
/// let threadSafeValue = ThreadSafeValue<Int>(0, qos: .background)
///
/// // Read the value synchronously
/// let currentValue = threadSafeValue.value
///
/// // Write the value asynchronously
/// threadSafeValue.value = 10
/// ```
class ThreadSafeValue<T> {
    
    // MARK: Properties
    
    /// The concurrent queue used to access the value.
    private let queue: DispatchQueue
    /// The value being wrapped.
    private var _value: T?
    
    /// The thread-safe value, which can be accessed both synchronously and asynchronously.
    var value: T? {
        get {
            var value: T?
            
            /// Read synchronously.
            queue.sync {
                value = _value
            }
            
            return value
        }
        
        set {
            /// Write asynchronously with barrier.
            queue.async(flags: .barrier) { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self._value = newValue
            }
        }
    }
    
    // MARK: Initialization
    
    /// Initializes a new instance of ThreadSafeValue.
    /// - Parameter value: The initial value for the ThreadSafeValue.
    /// - Parameter qos: The quality-of-service class for the underlying DispatchQueue.
    init(_ value: T? = nil, qos: DispatchQoS) {
        /// Save initial value.
        _value = value
        
        /// Initialize queue.
        queue = DispatchQueue(label: "com.company.appname.threadsafevalue", qos: qos, attributes: .concurrent)
    }
    
}
