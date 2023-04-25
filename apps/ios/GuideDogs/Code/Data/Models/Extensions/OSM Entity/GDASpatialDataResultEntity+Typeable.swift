//
//  GDASpatialDataResultEntity+Typeable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension GDASpatialDataResultEntity: Typeable {
    //Add a case here to add the primary type
    func isOfType(_ type: PrimaryType) -> Bool {
        switch type {
        case .transit: return isOfType(.transitStop)
        case .test: return false
        }
    }
    //It is unknown what this does yet
    func isOfType(_ type: SecondaryType) -> Bool {
        switch type {
        case .transitStop: return isTransitStop()
        }
    }
    //Why have this has its own function
    private func isTransitStop() -> Bool {
        guard let category = SuperCategory(rawValue: superCategory) else {
            return false
        }
        
        return category == .mobility && localizedName.lowercased().contains(GDLocalizedString("osm.tag.bus_stop").lowercased())
    }
    
}
