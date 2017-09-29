//
//  ViewController.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 11/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation

@objc
protocol CenterViewControllerDelegate {
    func toggleLeftPanel()
    func collapseSidePanel()
}

final class TrafficViewController: UIViewController, IncidentsParserDelegate, SidePanelViewControllerDelegate {
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate var incidents: [Incident]?
    fileprivate var operationQueue: OperationQueue?
    fileprivate lazy var imageProcessingQueue = OperationQueue()
    
    fileprivate var refresh = UIRefreshControl()
    fileprivate var locationManager = CLLocationManager()
    
    fileprivate let incidentsURLString = "http://www.freiefahrt.info/lmst.de_DE.xml"
    
    fileprivate var sortingMethod: SortingMethod = .byLocation {
        didSet {
            sortIncidents()
        }
    }
    
    weak var delegate: CenterViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh.addTarget(self, action: #selector(refreshView), for: .valueChanged)
        tableView.addSubview(refresh)
        
        locationManager.delegate = self
        
        // Register for force touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        loadIncidentsData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselecting a selected cell on returning from segue with animation
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    fileprivate func updateCurrentLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            sortingMethod = .byDate // Make default sorting by date because we have always time
        }
    }
    
    @objc func refreshView() {
        if operationQueue != nil && operationQueue!.operationCount > 0 {
            operationQueue?.cancelAllOperations()
        }
        
        // Update incidents
        loadIncidentsData()
    }
    
    fileprivate func loadIncidentsData() {
        if operationQueue != nil && operationQueue!.operationCount > 0 {
            // Downloading
            return
        }
        
        let feedURL = URL(string: incidentsURLString)
        
        operationQueue = OperationQueue()

        let parseOperation = IncidentsParseOperation(feedURL: feedURL!, delegate: self)

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        operationQueue?.addOperation(parseOperation)
    }
    
    fileprivate func handleLoadedIncidents(_ loadedIncidents: [Incident]) {
        
    }
    
    func incidentsParseOperation(_ parser: IncidentsParseOperation, loadedIncidents: [Incident], error: Error?) {
        // Although DispatchQueue does not retain self and there is no retain cycle here we don't
        // want to update incidents if the view is no longer there
        DispatchQueue.main.async { [weak self] in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self?.refresh.endRefreshing() // Stop refreshing
            
            if let error = error {
                UIAlertController.showInformationAlertController(title: "Error",
                                                                 message: error.localizedDescription,
                                                                 viewController: self)
            } else {
                self?.incidents = loadedIncidents
                self?.sortIncidents()
            }
        }
        
        operationQueue = nil
    }
    
    fileprivate func sortIncidents() {
        switch sortingMethod {
        case .byDate:
            self.incidents?.sort(by: sortIncidentsByDate)
            tableView.reloadData()
            scrollToTopOfTableView(tableView, animated: true)
            loadRoadSigns() // Load images for roadsigns
        case .byLocation:
            updateCurrentLocation()
        }
    }
    
    @IBAction func toggleSortOptions(_ sender: UIBarButtonItem) {
        delegate?.toggleLeftPanel()
    }
    
    func sortMethodSelected(_ sortBy: SortingMethod) {
        sortingMethod = sortBy
        delegate?.collapseSidePanel()
    }
    
    fileprivate func sortIncidentsByDate(firstIncident: Incident, secondIncident: Incident) -> Bool {
        // If time is ecual sort incidents by their summary in order to acheave constant
        // order of the incidents in different refreshs
        if firstIncident.time == secondIncident.time {
            return firstIncident.summary > secondIncident.summary
        }
        
        return firstIncident.time > secondIncident.time
    }
    
    
    fileprivate func sortIncidentsByLocation(_ firstIncident: Incident, _ secondIncident: Incident, _ location: CLLocation) -> Bool {
        // If locations avaliable compare them
        guard let firstLocation = firstIncident.location,
            let secondLocation = secondIncident.location else {
                // Some of the incidents don't provide any location. This sorts them at the end of the array
                return false
        }
        
        return location.distance(from: firstLocation) < location.distance(from: secondLocation)
        
    }
    
    fileprivate func loadRoadSigns() {
        guard let visibleCells = tableView.visibleCells as? [IncidentCell] else { return }
        for cell in visibleCells {
            if let indexPath = tableView.indexPath(for: cell) {
                let incident = incidents?[indexPath.row] // Takes current incident
                
                // If image is already loaded and set (by cellForIndexPath) there is
                // no need to load it again
                if incident?.image != nil {
                    cell.signImage.image = incident?.image // Load image in table
                    cell.setNeedsLayout() // Update cell view
                    continue
                }
                
                if let imageURL = incident?.imageURL { // If there is a URL
                    let session = URLSession.shared
                    let task = session.dataTask(with: imageURL, completionHandler: {
                        (data: Data?, response: URLResponse?, error: Error?) in
                        if error == nil, let data = data {
                            DispatchQueue.main.async {
                                incident?.image = UIImage(data: data) // Save image
                                cell.signImage.image = incident?.image // Load image in table
                                cell.setNeedsLayout() // Update cell view
                            }
                        }
                    })
                    
                    task.resume()
                }
            }
        }
    }
    
    fileprivate func scrollToTopOfTableView(_ tableView: UITableView, animated: Bool) {
        let topPoint = CGPoint(x: 0, y: 0 - tableView.contentInset.top)
        tableView.setContentOffset(topPoint, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowDetailsView:
            if let detailVC = segue.destination as? DetailsViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                detailVC.incident = incidents?[indexPath.row]
            }
        case .ShowMapView:
            if let mapVC = segue.destination as? IncidentsMapViewController {
                mapVC.incidents = incidents
            }
        }
    }
}

extension TrafficViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowDetailsView = "showDetailsView"
        case ShowMapView = "showMapView"
    }
}

extension TrafficViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incidents?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath) as! IncidentCell
        
        if let incident = incidents?[indexPath.row] {
            cell.configure(incident)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
}

extension TrafficViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Stop updating location because not needed anymore('till next update)
        locationManager.stopUpdatingLocation()
        
        // Get the last location
        if let currentLocation = locations.last {
            self.incidents?.sort { sortIncidentsByLocation($0, $1, currentLocation)}
            tableView.reloadData()
            scrollToTopOfTableView(tableView, animated: true)
            loadRoadSigns()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            UIAlertController.showInformationAlertController(title: "Failed loading Location!",
                                                             message: error.localizedDescription,
                                                             viewController: self)
        }
        
        sortingMethod = .byDate
    }
}

extension TrafficViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // When the user stops dragging on the table trigger update of roadsigns
        if !decelerate {
            loadRoadSigns()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadRoadSigns()
    }
}

extension TrafficViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let incident = incidents?[indexPath.row] else {
                return nil
        }
        
        if incident.location != nil {
            let controllerToCommit =
                UIViewController.initiateViewControllerWithIdentifier("IncidentsMapViewController") as? IncidentsMapViewController
            controllerToCommit?.incidents = [incident]
            return controllerToCommit
        } else {
            let controllerToCommit =
                UIViewController.initiateViewControllerWithIdentifier("DetailsViewController") as? DetailsViewController
            controllerToCommit?.incident = incident
            return controllerToCommit
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is DetailsViewController {
            navigationController?.pushViewController(viewControllerToCommit, animated: true)
            return
        }
        
        guard let incidentsMapViewController = viewControllerToCommit as? IncidentsMapViewController,
            let incident = incidentsMapViewController.incidents?.first,
            let index = incidents?.index(of: incident) else {
                return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        // Select the force touched cell in order to use normal segue transition
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        performSegueWithIdentifier(.ShowDetailsView, sender: self)
    }
}
