//
//  Extensions.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 29/03/16.
//  Copyright © 2016 LS1 TUM. All rights reserved.
//

import UIKit

extension UIViewController {
    static func initiateViewControllerWithIdentifier(_ identifier: String, fromStoryboard name: String = "Main") -> UIViewController? {
        return UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}
