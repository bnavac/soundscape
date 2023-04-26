//
//  LinkedList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A node in a doubly-linked list.
class LinkedListNode<T> {
    /// The value stored in this node.
    var value: T
    
    /// The next node in the list.
    var next: LinkedListNode<T>?
    
    /// The previous node in the list.
    weak var previous: LinkedListNode<T>?
    
    /// Creates a new node with the given value.
    /// - Parameter value: The value to be stored in the new node.
    init(_ value: T) {
        self.value = value
    }
}

/// A doubly-linked list of elements. A doubly-linked list is a data structure in which each element
/// contains a reference to the next and previous elements in the list, allowing for efficient
/// traversal in both directions. This implementation uses a `LinkedListNode` class to represent
/// the elements of the list, and provides methods for appending, removing, and retrieving elements
/// from the list.
///
/// Example usage:
/// ```
/// let list = LinkedList<Int>()
/// list.append(1)
/// list.append(2)
/// list.append(3)
/// list.remove(list.node(at: 1)!)
/// ```
class LinkedList<T> {
    /// The number of elements in the list.
    private(set) var count = 0
    
    /// Whether the list is empty.
    var isEmpty: Bool {
        return first == nil
    }
    
    /// The first node in the list.
    private(set) var first: LinkedListNode<T>?
    
    /// The last node in the list.
    private(set) weak var last: LinkedListNode<T>?
    
    /// Appends an element to the end of the list.
    /// - Parameter value: The value to be appended.
    func append(_ value: T) {
        let node = LinkedListNode(value)
        
        if let tail = last {
            node.previous = tail
            tail.next = node
        } else {
            first = node
        }
        
        last = node
        
        count += 1
    }
    
    /// Returns the node at the specified index.
    /// - Parameter at: The index of the node to retrieve.
    /// - Returns: The node at the specified index, or `nil` if the index is out of bounds.
    func node(at: Int) -> LinkedListNode<T>? {
        guard at >= 0 else {
            return nil
        }
        
        var node = first
        var index = at
        
        while node != nil {
            guard index > 0 else {
                return node
            }
            
            index -= 1
            node = node?.next
        }
        
        return nil
    }
    
    /// Removes all elements from the list.
    func clear() {
        first = nil
        last = nil
        count = 0
    }
    
    /// Removes the specified node from the list.
    ///
    /// - Parameter node: The node to be removed.
    /// - Returns: The value stored in the removed node.
    func remove(_ node: LinkedListNode<T>) -> T {
        let previous = node.previous
        let next = node.next
        
        if let prev = previous {
            prev.next = next
        } else {
            first = next
        }
        next?.previous = previous
        
        if next == nil {
            last = previous
        }
        
        count -= 1
        
        node.previous = nil
        node.next = nil
        
        return node.value
    }
}
