//
//  Token.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A class that represents a set of tokens in a string.
///
/// A token is a sequence of characters that is treated as a single entity in a parsing operation. In text processing, tokens are often created by splitting a string into substrings based on a separator character. For example, in the sentence "Hello, world!", the tokens are "Hello" and "world".
///
/// The `Token` class provides a way to parse a string into a set of tokens and to perform set operations on these tokens, such as computing their intersection.
///
/// Example usage:
///
/// ```
/// let token1 = Token(string: "apple, banana, cherry", separatedBy: ", ")
/// let token2 = Token(string: "banana, cherry, date", separatedBy: ", ")
///
/// let intersection = token1.intersection(other: token2)
///
/// print(intersection.tokenizedString) // Output: "banana, cherry"
/// ```
class Token {
    
    // MARK: Properties
    
    /// The separator used to separate tokens in the string.
    private let separator: String
    /// The set of tokens in the string.
    private let tokens: Set<String>
    /// The string with tokens separated by the separator.
    let tokenizedString: String
    
    // MARK: Initialization
    
    /// Initializes a new Token instance with the given set of tokens and separator.
    /// - Parameters:
    ///   - tokens: The set of tokens in the string.
    ///   - separator: The separator used to separate tokens in the string.
    private init(tokens: Set<String>, separatedBy separator: String) {
        self.separator = separator
        self.tokens = tokens
        self.tokenizedString = tokens.sorted(by: { return $0 < $1 }).joined(separator: separator)
    }
    
    /// Initializes a new Token instance with the set of tokens in the given string separated by the specified separator.
         
    /// - Parameters:
    ///   - string: The string containing the tokens to be parsed.
    ///   - separator: The separator used to separate tokens in the string.
    convenience init(string: String, separatedBy separator: String) {
        let stringTokens = Set(string.components(separatedBy: separator))
        self.init(tokens: stringTokens, separatedBy: separator)
    }
    
    // MARK: Token Functions
    
    /// Returns a new Token instance containing only the tokens that are common to both the current instance and the specified Token instance.
    /// - Parameters:
    ///   - other: The Token instance to compare with the current instance.
    /// - Returns: A new Token instance containing only the tokens that are common to both the current instance and the specified Token instance.
    func intersection(other: Token) -> Token {
        let intersectionTokens = tokens.intersection(other.tokens)
        return Token(tokens: intersectionTokens, separatedBy: separator)
    }
}
