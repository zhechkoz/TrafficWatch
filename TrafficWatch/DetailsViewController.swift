//
//  DetailsViewController.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 12/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SafariServices

final class DetailsViewController: UIViewController {
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var summaryTextView: UITextView!
    @IBOutlet weak private var mapView: MKMapView!
    @IBOutlet weak private var mapNotFoundImage: UIImageView!
    @IBOutlet weak private var changeMapTypeSegment: UISegmentedControl!
    @IBOutlet weak private var changeMapTypeButton: UIButton!
    @IBOutlet weak private var showCurrentLocationButton: UIButton!
    
    private final let defaultCornerRadius: CGFloat = 5
    
    var incident: Incident?
    
    private var mapTypeSegmentControlShouldHide: Bool = true {
        didSet {
            let originalFrame = changeMapTypeSegment.frame
			let smallFrame = CGRect(x: originalFrame.origin.x + originalFrame.width,
			                        y: originalFrame.origin.y, width: 0, height: originalFrame.height)
			
			let hideAnimation = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 6) {
				[weak self] in
				self?.changeMapTypeSegment.frame = smallFrame
				self?.changeMapTypeSegment.alpha = 0
				self?.changeMapTypeButton.alpha = 1
			}
			
			hideAnimation.addCompletion {
				[weak self] _ in
				self?.changeMapTypeSegment.frame = originalFrame
			}
			
			let showAnimation = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 6) {
				[weak self] in
				self?.changeMapTypeSegment.frame = originalFrame
				self?.changeMapTypeSegment.alpha = 1
				self?.changeMapTypeButton.alpha = 0
			}
			
			if mapTypeSegmentControlShouldHide {
				hideAnimation.startAnimation()
			} else {
				changeMapTypeSegment.frame = smallFrame
				showAnimation.startAnimation()
			}
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
		
        titleLabel.text = incident?.title
		
        // Resolves bug with not setting right the font
        summaryTextView.isSelectable = true
        summaryTextView.text = incident?.summary
        summaryTextView.isSelectable = false
		
        // We don't need the big title bar because of readability concerns
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // Determine if incident location exists
        if let location = incident?.location {
            mapView.delegate = self
            
            if CLLocationManager.authorizationStatus() == .authorizedAlways ||
                CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
				mapView.showsUserLocation = true
            } else {
                showCurrentLocationButton.isEnabled = false
            }
        
            // Image for map not available is removed before the map location is set
            mapNotFoundImage.removeFromSuperview()
        
            // Hide the segment because it is only accessible after a button press
			changeMapTypeSegment.alpha = 0
			
            // Sets segment's subviews to clip
			changeMapTypeSegment.clipsToBounds = true
        
            // Makes buttons' and segment's view edges round
            changeMapTypeSegment.layer.cornerRadius = defaultCornerRadius
            changeMapTypeButton.layer.cornerRadius = defaultCornerRadius
            showCurrentLocationButton.layer.cornerRadius = defaultCornerRadius
			
			let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let viewRegion = MKCoordinateRegionMake(location.coordinate, span)
            
            // Set view of the better view place
            mapView.setRegion(viewRegion, animated: false)
			
			// Show incident on map
            mapView.addAnnotation(incident!)
        } else {
            // If there is no location display the map not found image and remove everything else
            mapView.removeFromSuperview()
            changeMapTypeButton.removeFromSuperview()
            changeMapTypeSegment.removeFromSuperview()
            showCurrentLocationButton.removeFromSuperview()
        }
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        
        // Scroll summary text to top because the default is scrolled to the bottom
        summaryTextView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        
        mapView.layer.cornerRadius = UIDevice.current.orientation.isLandscape ? defaultCornerRadius : 0
	}
	
    @IBAction func mapTypeButtonPressed() {
        mapTypeSegmentControlShouldHide = false
    }
    
    @IBAction func showCurrentLocationButtonPressed(_ sender: UIButton) {
		let location = incident!.location!.coordinate
        let userLocation = mapView.userLocation.coordinate
        
        // Finds the middle of the two points
        let latitude = location.latitude - (location.latitude - userLocation.latitude) * 0.5
        let longitude = location.longitude + (userLocation.longitude - location.longitude) * 0.5
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Determine the shown span with a little extra
        let span = MKCoordinateSpan(latitudeDelta: fabs(location.latitude - userLocation.latitude) * 1.3,
            longitudeDelta: fabs(userLocation.longitude - location.longitude) * 1.3)
        
        let mapRegion = MKCoordinateRegion(center: center, span: span)
        let region = mapView.regionThatFits(mapRegion)
        
        mapView.setRegion(region, animated: true)
        
        mapTypeSegmentControlShouldHide = true
    }
    
    @IBAction func mapTypeSegmentControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                mapView.mapType = .standard
            case 1:
                mapView.mapType = .hybrid
            default:
                mapView.mapType = .satellite
        }
        
        mapTypeSegmentControlShouldHide = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if changeMapTypeSegment.alpha > 0 {
            mapTypeSegmentControlShouldHide = true
        }
    }
    
    @IBAction func openInSafariButtonTouched() {
		guard let incident = incident, let url = URL(string: incident.weblink),
			let context = UIApplication.shared.keyWindow?.rootViewController else { return }
		
		let safari = SFSafariViewController(url: url)
		safari.delegate = self
		
		context.present(safari, animated: true, completion: nil)
    }
}

extension DetailsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension DetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
		if CLLocationManager.authorizationStatus() == .notDetermined {
			UIAlertController.showAlertController(title: "Turn On Location Services to Allow Traffic Watch to Determine Your Location",
			                   message: nil, viewController: self, approveActionTitle: "Settings", approveAction: {
                _ in
                // Open settings to allow the user change settings
                let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
								UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
                
            }, cancelAction: nil)
		}
    }
}
