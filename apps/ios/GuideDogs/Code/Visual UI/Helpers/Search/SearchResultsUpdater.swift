//
//  SearchResultsUpdater.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol SearchResultsUpdaterDelegate: AnyObject {
    func searchResultsDidStartUpdating()
    func searchResultsDidUpdate(_ searchResults: [POI], searchLocation: CLLocation?)
    func searchResultsDidUpdate(_ searchForMore: String?)
    func searchWasCancelled()
    var isPresentingDefaultResults: Bool { get }
    var telemetryContext: String { get }
    // Set `isCachingRequired = true` if a selected search result will
    // be cached on device
    // Search results can only be cached when an unencumbered coordinate is available
    var isCachingRequired: Bool { get }
}

class SearchResultsUpdater: NSObject {
    
    enum Context {
        case partialSearchText
        case completeSearchText
    }
    
    // MARK: Properties
    weak var delegate: SearchResultsUpdaterDelegate?
    private var searchRequestToken: RequestToken?
    private var searchResultsUpdating = false
    private(set) var searchBarButtonClicked = false
    private var location: CLLocation?
    var context: Context = .partialSearchText
    
    // MARK: Initialization
    
    override init() {
        super.init()
        
        // Save user's current location
        location = AppContext.shared.geolocationManager.location
        
        // Observe changes in user's location
        // This is required so that we can present all search
        // results with an accurate distance
        NotificationCenter.default.addObserver(self, selector: #selector(self.onLocationUpdated(_:)), name: Notification.Name.locationUpdated, object: nil)
    }
    
    deinit {
        searchRequestToken?.cancel()
    }
    
    // MARK: Notifications
    
    @objc
    private func onLocationUpdated(_ notification: Notification) {
        guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
            return
        }
        
        self.location = location
    }
    
    // MARK: Selecting Search Results
    
    func selectSearchResult(_ poi: POI, completion: @escaping (SearchResult?, SearchResultError?) -> Void) {
        if let delegate = delegate, delegate.isPresentingDefaultResults {
            GDATelemetry.track("recent_entity_selected.search", with: ["context": delegate.telemetryContext])
            completion(.entity(poi), nil)
        } else {
            completion(.entity(poi), nil)
        }
    }
    
}

// MARK: - UISearchResultsUpdating
//An extension that comes from the original UISearchController
extension SearchResultsUpdater: UISearchResultsUpdating {
    //Note that this function runs every time the user types in text
    func updateSearchResults(for searchController: UISearchController) {
        searchBarButtonClicked = false
        
        if let searchBarText = searchController.searchBar.text, !searchBarText.isEmpty {
            // Fetch new search results
            switch context {
            case .partialSearchText: partialSearchWithText(searchText: searchBarText)
            case .completeSearchText: searchWithText(searchText: searchBarText)
            }
        } else {
            searchResultsUpdating = false
            // There is no search text
            // Clear current search results
            delegate?.searchResultsDidUpdate([], searchLocation: nil)
        }
    }
    
    private func partialSearchWithText(searchText: String) {
        if searchResultsUpdating == false {
            searchResultsUpdating = true
            // Notify the delegate when a new update
            // begins
            delegate?.searchResultsDidStartUpdating()
        }
        
        guard AppContext.shared.offlineContext.state == .online else {
            return
        }
        
        GDATelemetry.track("autosuggest.request_made", with: ["context": delegate?.telemetryContext ?? ""])
        
        searchRequestToken?.cancel()
        
        //
        // Fetch autosuggest results with new search text
        //
        //Note that we use the same code here and also in searchWithText
        //There are a few limitations with this design, namely that it will only get POIS in the nearby area. So if the user wants to go anywhere that is not within (500?) (feet?meters?) of them, they are out of luck.
        //Second, the code grabs a new set of POIs each time and does a linear search through each. This is really inefficent, but given the small amount of POIs we have, fixing the first issue is more pressing.
        if(searchText == ""){
            return
        }
        //Grab each nearby POI
        let nearbyData = NearbyDataContext(location: AppContext.shared.geolocationManager.location)
        //Filter POIs by just finding a match through in names
        var pois: [POI] = []
        for poi in nearbyData.pois {
            if(poi.name.lowercased().contains(searchText.lowercased())){
                pois.append(poi)
            }
        }
        //Return the result
        delegate?.searchResultsDidUpdate(pois, searchLocation: AppContext.shared.geolocationManager.location)
    }
    
}

// MARK: - UISearchBarDelegate

extension SearchResultsUpdater: UISearchBarDelegate {
    //Runs whenever the user presses enter on the search bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBarButtonClicked = true
        
        guard let searchBarText = searchBar.text, searchBarText.isEmpty == false else {
            // Return if there is no search text
            return
        }
        
        self.searchWithText(searchText: searchBarText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchWasCancelled()
    }
    
    private func searchWithText(searchText: String) {
        // Notify the delegate when a new update
        // begins
        delegate?.searchResultsDidStartUpdating()
        
        guard AppContext.shared.offlineContext.state == .online else {
            return
        }
        
        GDATelemetry.track("search.request_made", with: ["context": delegate?.telemetryContext ?? ""])
        
        searchRequestToken?.cancel()
        
        //
        // Fetch search results given search text
        //
        if(searchText == ""){
            return
        }
        //Grab each nearby POI
        let nearbyData = NearbyDataContext(location: AppContext.shared.geolocationManager.location)
        //Filter POIs by just finding a match through in names
        var pois: [POI] = []
        for poi in nearbyData.pois {
            if(poi.name.lowercased().contains(searchText.lowercased())){
                pois.append(poi)
            }
        }
        //Return the result somehow
        delegate?.searchResultsDidUpdate(pois, searchLocation: AppContext.shared.geolocationManager.location)
    }
    
}
