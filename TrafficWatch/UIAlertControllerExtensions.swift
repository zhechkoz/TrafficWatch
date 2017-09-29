//
//  UIAlertControllerExtensions.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 27/06/15.
//  Copyright © 2015 LS1 TUM. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func showInformationAlertController(title: String!, message: String?, viewController: UIViewController?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showAlertController(title: String!, message: String?, viewController: UIViewController?, approveActionTitle: String,
                                   approveAction: ((UIAlertAction?) -> Void)?, cancelAction: ((UIAlertAction?) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelAction)
        let settingsAction = UIAlertAction(title: approveActionTitle, style: .default, handler: approveAction)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        viewController?.present(alert, animated: true, completion: nil)
    }
}
