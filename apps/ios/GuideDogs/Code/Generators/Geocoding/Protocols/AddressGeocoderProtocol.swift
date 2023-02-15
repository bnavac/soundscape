//
//  AddressGeocoderProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//Geocoder protocol is a protocol that contains the string of an address, as well as
//a definition for a reverse geocoder - which is finding a location using the latitutde
//and longitude. See here: https://medium.com/aeturnuminc/geocoding-in-swift-611bda45efe1
import Foundation
import CoreLocation

protocol AddressGeocoderProtocol {
    func geocodeAddressString(_ addressString: String, in region: CLRegion?, preferredLocale locale: Locale?, completionHandler: @escaping CLGeocodeCompletionHandler)
    func reverseGeocodeLocation(_ location: CLLocation, preferredLocale locale: Locale?, completionHandler: @escaping CLGeocodeCompletionHandler)
    func cancelGeocode()
}

extension CLGeocoder: AddressGeocoderProtocol { }
