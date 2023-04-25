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
    //Returns true if the secondary type is a type in the enum (Which should always be true)
    //Assuming that you add additional cases to this method
    //Though if you do add more cases, then the method will always return true and so this method is basically useless (So why is it here?)
    func isOfType(_ type: SecondaryType) -> Bool {
        switch type {
        case .transitStop: return isTransitStop()
        default: return false
        }
    }
    //Why is this its own function?
    private func isTransitStop() -> Bool {
        guard let category = SuperCategory(rawValue: superCategory) else {
            return false
        }
        
        return category == .mobility && localizedName.lowercased().contains(GDLocalizedString("osm.tag.bus_stop").lowercased())
    }
    
}
