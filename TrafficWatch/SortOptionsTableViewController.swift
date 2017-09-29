//
//  LeftViewController.swift
//  SlideOutNavigation
//
//  Created by James Frost on 03/08/2014.
//  Copyright (c) 2014 James Frost. All rights reserved.
//

import UIKit
import CoreLocation

protocol SidePanelViewControllerDelegate: class {
    func sortMethodSelected(_ sortBy: SortingMethod)
}

enum SortingMethod {
    case byDate
    case byLocation
}

final class SortOptionsTableViewController: UITableViewController {
    
    weak var delegate: SidePanelViewControllerDelegate?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            var selectedMethod = SortingMethod.byLocation
            
            if CLLocationManager.authorizationStatus() == .denied ||
                CLLocationManager.authorizationStatus() == .restricted {
                UIAlertController
                    .showAlertController(title: "Turn On Location Services to Allow Traffic Watch to Determine Your Location",
                                         message: nil,
                                         viewController: self, approveActionTitle: "Settings",
                        approveAction: { _ in
                            // Open settings to allow the user change settings
                            let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
							UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
                        }, cancelAction: {
                                _ in
                            selectedMethod = .byDate
                    })
            }
            
            delegate?.sortMethodSelected(selectedMethod)
        default:
            delegate?.sortMethodSelected(.byDate)
        }
    }    
}
