//
//  GDASpatialDataResultEntity+Typeable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension GDASpatialDataResultEntity: Typeable {
    //Add a case here to add the primary type to the Places Nearby menu
    func isOfType(_ type: PrimaryType) -> Bool {
        switch type {
        //There are three examples of using this method. If you want a general filter grab, such as every landmark, you can just call the method directly. But if you wanted a specific filter, such as bus stops or steps, you can call isOfType(secondaryType). Finally, if you want something that isn't as specific or general, ie the most popular case, use isAmenity. Note that since amenities are optional there is a chance that some POIs will be excluded if they do not have the appropriate amenity.
            case .transit: return isOfType(.transitStop)
            case .food: return isAmenity(amenities: ["cafe", "restaurant", "fast_food"])
            case .landmarks: return isLandmark()
        }
    }
    //Returns true if the method for the secondary type is true
    func isOfType(_ type: SecondaryType) -> Bool {
        switch type {
            case .transitStop: return isTransitStop()
            case .steps: return isSteps()
            //We will never reach the default case but it is here to avoid an infinite loop
            default: return false
        }
    }
    //Returns true if the category of the POI is mobility and if the POI contains the text "bus stop"
    //Because of this fairly strict text matching, this method, and the similar ones, such as isSteps, are fairly restrictive in that they will get very specific information. So these methods have limited use in practice outside of user defined filters. So, as a default filter, this is woefully inadequate.
    private func isTransitStop() -> Bool {
        guard let category = SuperCategory(rawValue: superCategory) else {
            return false
        }
        return category == .mobility && localizedName.lowercased().contains(GDLocalizedString("osm.tag.bus_stop").lowercased())
    }
    //Return true if the category of the POI is mobility and if the name contains the word "steps"
    private func isSteps() -> Bool{
        guard let category = SuperCategory(rawValue:superCategory) else {
            return false
        }
        return category == .mobility &&
        localizedName.lowercased().contains(GDLocalizedString("osm.tag.steps").lowercased())
    }
    //Returns true if the category if the POI is a landmark.
    private func isLandmark() -> Bool{
        guard let category = SuperCategory(rawValue:superCategory) else {
            return false
        }
        return category == .landmarks
    }
    //Returns true if the POI's amenities match one of the given amenities
    private func isAmenity(amenities: [String]) -> Bool{
        for amenity in amenities {
            if(amenity == self.amenity){
                return true
            }
        }
        return false
    }
}
