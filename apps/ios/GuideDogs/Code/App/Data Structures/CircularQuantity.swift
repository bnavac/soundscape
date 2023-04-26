//
//  CircularQuantity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// An immutable value representing an angle, in degrees and radians.
///
/// The angle of `CircularQuantity` is normailzed,so the value will always be between 0 and 360
/// degrees, or 0 and 2π radians.
///
/// Example usage:
///
/// ```
/// let angleInDegrees = CircularQuantity(valueInDegrees: 45.0)
/// let angleInRadians = CircularQuantity(valueInRadians: Double.pi / 4)
/// let sum = angleInDegrees + angleInRadians
/// print("The sum is \(sum)")
/// ```
struct CircularQuantity {

    // MARK: Properties
    
    /// The angle in degrees.
    let valueInDegrees: Double
    /// The angle in radians.
    let valueInRadians: Double
    
    // MARK: Initialization
    
    /// Creates a new `CircularQuantity` with the given angle in degrees.
    /// - Parameter valueInDegrees: The angle in degrees.
    init(valueInDegrees: Double) {
        self.valueInDegrees = valueInDegrees
        self.valueInRadians = valueInDegrees.degreesToRadians
    }
    
    /// Creates a new `CircularQuantity` with the given angle in radians.
    /// - Parameter valueInRadians: The angle in radians.
    init(valueInRadians: Double) {
        self.valueInDegrees = valueInRadians.radiansToDegrees
        self.valueInRadians = valueInRadians
    }
    
    // MARK: -
    
    /// Returns a new `CircularQuantity` object with an angle equivalent to the original angle within a range of 0 to 360 degrees.
    /// - Returns: A normalized `CircularQuantity`.
    func normalized() -> CircularQuantity {
        var constant = 1.0
        
        if abs(valueInDegrees) > 360.0 {
            constant = ceil( abs(valueInDegrees) / 360.0 )
        }
        
        let nValueInDegrees = fmod(valueInDegrees + ( constant * 360.0 ), 360.0)
        return CircularQuantity(valueInDegrees: nValueInDegrees)
    }
    
}

/// Add the ability to use common operators the compare one `CircularQuantity` to another.
extension CircularQuantity: Comparable {
    
    /// Returns a Boolean value indicating whether two `CircularQuantity` values are equal.
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: `true` if the values are equal, otherwise `false`.
    static func == (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees == rhs.normalized().valueInDegrees
    }
    
    /// Returns a Boolean value indicating whether the first `CircularQuantity` value is greater than the second.
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: `true` if the first value is greater, otherwise `false`.
    static func > (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees > rhs.normalized().valueInDegrees
    }
    
    /// Returns a Boolean value indicating whether the first `CircularQuantity` value is less than the second.
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: `true` if the first value is less, otherwise `false`.
    static func < (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees < rhs.normalized().valueInDegrees
    }
    
    /// Returns a new `CircularQuantity` object representing the sum of the two given `CircularQuantity` values.
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    /// - Returns: The sum of the two values as a `CircularQuantity`.
    static func + (lhs: CircularQuantity, rhs: CircularQuantity) -> CircularQuantity {
        let sum = lhs.normalized().valueInDegrees + rhs.normalized().valueInDegrees
        return CircularQuantity(valueInDegrees: sum).normalized()
    }
    
    /// Returns a new `CircularQuantity` object representing the difference between the two given `CircularQuantity` values.
    /// - Parameters:
    ///   - lhs: The value to subtract from.
    ///   - rhs: The value to subtract.
    /// - Returns: The difference between the two values as a `CircularQuantity`.
    static func - (lhs: CircularQuantity, rhs: CircularQuantity) -> CircularQuantity {
        let difference = lhs.normalized().valueInDegrees - rhs.normalized().valueInDegrees
        return CircularQuantity(valueInDegrees: difference).normalized()
    }
    
    /// Returns a new `CircularQuantity` object representing the negation of the given `CircularQuantity` value.
    /// - Parameter value: The value to negate.
    /// - Returns: The negation of the value as a `CircularQuantity`.
    prefix static func - (value: CircularQuantity) -> CircularQuantity {
        let valueInDegrees = value.valueInDegrees
        return CircularQuantity(valueInDegrees: -valueInDegrees).normalized()
    }
    
}

/// Allow `CircularQuantity` to be printed and turned to a string implicitly.
extension CircularQuantity: CustomStringConvertible {
    /// A textual representation of the `CircularQuantity`.
    public var description: String {
        return "\(valueInDegrees)"
    }
    
}
