//
//  Queue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A generic queue data structure that operates on a First-In, First-Out (FIFO) basis.
///
/// To create an empty `Queue<T>`, simply call the default initializer:
///
/// ```
/// var myQueue = Queue<Int>()
/// ```
///
/// Elements can be added to the `Queue<T>` using the `enqueue(_:)` method, and removed using the `dequeue()` method.
///
/// ```
/// myQueue.enqueue(1)
/// myQueue.enqueue(2)
/// let first = myQueue.dequeue() // first == 1
/// let second = myQueue.dequeue() // second == 2
/// ```
///
/// The `clear()` method can be used to remove all elements at once, and the `peek()` method can be used to
/// inspect the element at the front without removing it.
///
/// ```
/// myQueue.enqueue(1)
/// let front = myQueue.peek() // front == 1
/// ```
///
/// `Queue<T>` supports any type that conforms to the `Equatable` protocol. If you need to use a custom type that does not
/// conform to `Equatable`, you will need to implement the `Equatable` protocol yourself or provide a custom `==` operator
/// for your type.
struct Queue<T> {
    
    // MARK: Properties
    
    /// The underlying linked list that the Queue is based on.
    private var list: LinkedList<T>
    
    /// A serial dispatch queue that ensures thread safety for the Queue.
    private let queue = DispatchQueue(label: "com.company.appname.queue")
    
    /// The number of elements currently in the Queue.
    var count: Int {
        return queue.sync {
            return list.count
        }
    }
    
    /// A Boolean value indicating whether the Queue is empty.
    var isEmpty: Bool {
        return queue.sync {
            return list.isEmpty
        }
    }
    
    // MARK: Initialization
    
    /// Initializes an empty Queue.
    init() {
        list = LinkedList<T>()
    }
    
    // MARK: -
    
    /// Adds an element to the end of the Queue.
    /// - Parameter value: The element to add to the Queue.
    public mutating func enqueue(_ value: T) {
        queue.sync {
            list.append(value)
        }
    }
    
    /// Removes and returns the element at the front of the Queue.
    /// - Returns: The element at the front of the Queue, or nil if the Queue is empty.
    public mutating func dequeue() -> T? {
        return queue.sync { () -> T? in
            guard let item = list.first else {
                return nil
            }
            
            return list.remove(item)
        }
    }
    
    /// Removes all elements from the Queue.
    public mutating func clear() {
        queue.sync {
            list.clear()
        }
    }
    
    /// Returns the element at the front of the Queue without removing it.
    /// - Returns: The element at the front of the Queue, or nil if the Queue is empty.
    public func peek() -> T? {
        return queue.sync {
            return list.first?.value
        }
    }
}
