//
//  PrimaryType.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
//Enum that defines a type for a POI ie Transit, Food, Healthcare, etc.
enum PrimaryType: String, CaseIterable, Type {
    //Add cases here to add new types for places nearby
    case transit
    case test
    func matches(poi: POI) -> Bool {
        guard let typeable = poi as? Typeable else {
            return false
        }
        
        return typeable.isOfType(self)
    }
    
}
