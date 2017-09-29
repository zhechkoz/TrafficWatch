//
//  AllIncidentsMapViewController.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 30/06/15.
//  Copyright © 2015 LS1 TUM. All rights reserved.
//

import UIKit
import MapKit

final class IncidentsMapViewController: UIViewController {
    
    @IBOutlet weak fileprivate var mapView: MKMapView!
    
    var incidents: [Incident]? {
        didSet {
            validIncidents = incidents?.filter { $0.location != nil }
        }
    }
    fileprivate var validIncidents: [Incident]?
    fileprivate var isInitialStart = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        mapView.addAnnotations(validIncidents ?? [])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedAnnotations = mapView.selectedAnnotations
        mapView.deselectAnnotation(selectedAnnotations.first, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowIncidentsDetails:
            if let detailsVC = segue.destination as? DetailsViewController {
                detailsVC.incident = sender as? Incident
            }
        }
    }
}

extension IncidentsMapViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowIncidentsDetails = "showIncidentDetails"
    }
}

extension IncidentsMapViewController: MKMapViewDelegate {
	func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Set visible map region according to annotations only the first time it loads
        if isInitialStart {
            mapView.showAnnotations(mapView.annotations, animated: false)
            isInitialStart = false
        }
	}
	
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "incidentView"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        annotationView?.canShowCallout = true
        annotationView?.annotation = annotation
        annotationView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                                       calloutAccessoryControlTapped control: UIControl) {
        performSegueWithIdentifier(.ShowIncidentsDetails, sender: view.annotation)
    }
}
