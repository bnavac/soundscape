//
//  Promise.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A minimal promise implementation which allows for asynchronously generating a value (a.k.a. "fulfilling the promise").
///
/// Example usage:
///
/// ```
/// let promise = Promise<Int> { resolve in
///     DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
///     resolve(42)
///     }
/// }
///
/// promise.then { value in
///     print("The value is \(value)")
/// }
/// ```
class Promise<Value> {
    /// Possible states of the promise.
    enum State<T> {
        case pending
        case resolved(T)
    }

    /// The current state of the promise.
    var state: State<Value> = .pending
    
    /// The closure which will be called when the promise is fulfilled.
    typealias Resolver = (Value) -> Void
    
    /// The dispatch queue used to synchronize access to the promise.
    private let queue = DispatchQueue(label: "com.company.appname.promise")
    
    /// Array of callbacks to pass the value to when fulfilling the promise.
    private var callbacks: [Resolver] = []

    /// Creates a new promise and executes the executor closure.
    /// - Parameter executor: A closure which generates the value and fulfills the promise.
    init(executor: (_ resolve: @escaping Resolver) -> Void) {
        executor(resolve)
    }

    /// Method for subscribing to the promise. If the promise is already in the resolved state, the resolver
    /// method passed in will be called immediately. If not, it will be stored until the value is generated and
    /// will then be called.
    /// - Parameter onResolved: A code block to call when the promise is fulfilled
    func then(onResolved: @escaping Resolver) {
        queue.sync {
            self.callbacks.append(onResolved)
            self.triggerCallbacksIfResolved()
        }
    }
    
    /// Method passed in the executor which should be called when the value has been
    /// generated and the promised should be fulfilled.
    /// - Parameter value: The value to fulfill the promise with.
    private func resolve(_ value: Value) {
        updateState(to: .resolved(value))
    }

    /// Updates the state of the promise to the given state.
    /// - Parameter newState: The new state of the promise.
    private func updateState(to newState: State<Value>) {
        guard case .pending = state else {
            return
        }
        
        state = newState
        triggerCallbacksIfResolved()
    }

    /// Triggers all the stored callbacks if the promise is in the resolved state.
    private func triggerCallbacksIfResolved() {
        guard case let .resolved(value) = state else {
            return
        }
        
        // We trigger all the callbacks
        queue.async {
            self.callbacks.forEach { callback in callback(value) }
            self.callbacks.removeAll()
        }
    }
}
