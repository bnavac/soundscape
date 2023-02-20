//
//  IdentifiableAnnotation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit      //https://developer.apple.com/documentation/mapkit/


struct IdentifiableAnnotation: Identifiable {
    let id = UUID()
    let annotation: MKAnnotation
}

extension MKAnnotation {
    
    var asIdentifiable: IdentifiableAnnotation {
        return IdentifiableAnnotation(annotation: self)
    }
    
}
