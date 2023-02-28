//
//  MapViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  This file is the view map on the screen
//  File uses MapKit which displays Apple Map on to the screen
//  Find MKMapViewDelegate+Extensions.swift
//  Go to Code -> App -> Framework Extension -> MapKit -> MKMapViewDelegate+Extensions.swift
//  LocationDetail is used in MKMapView, MKMapViewDelegate, and many more code files
//  For the UI, maps uses LocationDetail to annotate the location and it
//  LocationDetail holds RouteWaypoint which is related to Realm
//
//  Annotation is MKAnnotation, manages the data that you want to display on the map surface.

import Foundation
import MapKit
import Combine     //  https://developer.apple.com/documentation/combine
                   //  combine the output of multiple publishers and coordinate their interaction
                   //  centralizes event-processing code and eliminates troublesome techniques like nested closures and convention-based callbacks

// didSelect tells the delegate when the user selects one or more of its annotation views.
protocol MapViewControllerDelegate: AnyObject {
    func didSelectAnnotation(_ annotation: MKAnnotation)
}

class MapViewController: UIViewController {
    
    // MARK: `IBOutlet`
    // IBOutlet is a tag connected to an property declaration so that the Interface Builder
    // application can recognize the property as an outlet and sync the display and connection
    // of it with Xcode
    
    @IBOutlet private weak var mapView: MKMapView!
    
    // MARK: Properties
    
    weak var delegate: MapViewControllerDelegate?
    private var listeners: [AnyCancellable] = []
    
    var style: MapStyle? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            mapView.configure(for: style)
        }
    }
    
    // MARK: View Life Cycle
    // https://medium.com/good-morning-swift/ios-view-controller-life-cycle-2a0f02e74ff5
    // thing to do during the view controller life cycle
    
    // called when all views are loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.accessibilityIgnoresInvertColors = true
        
        // Hide accessibility elements for the map view
        mapView.accessibilityElementsHidden = true
    }
    
    // called every time before the view is visible to and before any animation is configured
    // override this method to perform custom tasks associated with displaying the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.configure(for: style)
        
        // Ensure the tint color is not overwritten by a parent view
        mapView.tintColor = UIColor.systemBlue
        
        // State of active route has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.routeGuidanceStateChanged).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard case .route = self.style else {
                return
            }
            
            // Route guidance is active - Update the map so that
            // it is centered on the new, current waypoint
            self.mapView.configure(for: self.style)
        })
        
        // State of active tour has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.tourStateChanged).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard case .tour = self.style else {
                return
            }
            
            // Tour guidance is active - Update the map so that
            // it is centered on the new, current waypoint
            self.mapView.configure(for: self.style)
        })
    }
    
    // called before the view is removed from the view hierarchy
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        listeners.cancelAndRemoveAll()
    }
    
}

extension MapViewController: MKMapViewDelegate {
    // calls functions in MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? LocationDetailAnnotation {
            return self.mapView(mapView, viewForLocationDetailAnnotation: annotation)
        }
        
        if let annotation = annotation as? WaypointDetailAnnotation {
            let canShowCallout: Bool
            
            switch style {
            case .route(let detail):
                // Disable the detail disclosure callout if the activity has expired
                canShowCallout = !detail.isExpiredTrailActivity
            case .tour:
                canShowCallout = true
            default:
                canShowCallout = false
            }
                
            return self.mapView(mapView, viewForWaypointDetailAnnotation: annotation, canShowCallout: canShowCallout)
        }
        
        if let annotation = annotation as? MKClusterAnnotation {
            return self.mapView(mapView, viewForClusterAnnotation: annotation)
        }
        
        return nil
    }
    // Using DispatchQueue.main makes sure UI updates on the main queue
    // Using async to avoid blocking the current thread
    // https://www.donnywals.com/appropriately-using-dispatchqueue-main/
    // return out the function if failed -> self is the same or annotation is the same
    // otherwise do didSelectAnnotation
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard let annotation = view.annotation else {
                return
            }
            
            self.delegate?.didSelectAnnotation(annotation)
        }
    }
    
}
