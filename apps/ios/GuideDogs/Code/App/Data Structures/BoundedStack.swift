//
//  BoundedStack.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

/// A stack with a fixed capacity.
/// Use a bounded stack when you need a stack with a fixed size, and you want to limit the amount of elements that can be stored in it. This implementation automatically removes the oldest elements from the stack when the capacity is exceeded.
public struct BoundedStack<T> {
    /// The maximum number of elements that can be stored in the stack.
    private(set) var bound: UInt
    /// The elements currently stored in the stack.
    private(set) var elements: [T] = []
    
    /// Creates a new bounded stack with the given capacity.
    /// - Parameter bound: The maximum number of elements that can be stored in the stack.
    public init(bound: UInt) {
        if bound == 0 {
            fatalError("The BoundedStack must have a bound greater than zero!")
        }
        
        self.bound = bound
    }
    
    // MARK: Stack manipulation
    
    /// Adds an element to the top of the stack.
    /// If the stack is already at full capacity, the oldest element in the stack will be removed to make room for the new element.
    /// - Parameter value: The element to add to the stack.
    public mutating func push(_ value: T) {
        elements.append(value)
        
        if elements.count > bound {
            elements.removeFirst()
        }
    }
    
    /// Adds a sequence of elements to the top of the stack.
    /// If the stack exceeds its capacity, the oldest elements in the stack will be removed to make room for the new elements.
    /// - Parameter array: The sequence of elements to add to the stack.
    public mutating func push(contentsOf array: [T]) {
        elements.append(contentsOf: array)
        
        if elements.count > bound {
            elements.removeFirst(elements.count - Int(bound))
        }
    }
    
    /// Removes and returns the element at the top of the stack.
    /// If the stack is empty, this method returns `nil`.
    /// - Returns: The element that was removed from the stack, or `nil` if the stack was empty.
    public mutating func pop() -> T? {
        guard !elements.isEmpty else {
            return nil
        }
        
        return elements.removeLast()
    }
    
    /// Removes all elements from the stack that match the given predicate.
    /// - Parameter predicate: The predicate to use to filter the elements.
    /// - Returns: An array containing the elements that were removed from the stack.
    public mutating func remove(where predicate: (T) -> Bool) -> [T] {
        var removed: [T] = []
        
        while let index = elements.firstIndex(where: predicate) {
            removed.append(elements.remove(at: index))
        }
        
        return removed
    }
    
    /// Removes all elements from the stack.
    public mutating func clear() {
        elements.removeAll()
    }
    
    /// Returns the element at the top of the stack without removing it.
    /// If the stack is empty, this method returns `nil`.
    /// - Returns: The element at the top of the stack, or `nil` if the stack is empty.
    public func peek() -> T? {
        return elements.last
    }
    
    /// Returns `true` if the stack is empty, `false` otherwise.
    public var isEmpty: Bool { return elements.isEmpty }
    
    /// The number of elements currently stored in the stack.
    public var count: Int { return elements.count }
}
