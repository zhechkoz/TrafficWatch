//
//  SegueHandlerType.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 30/06/15.
//  Copyright © 2015 LS1 TUM. All rights reserved.
//

import UIKit

protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController,
                            SegueIdentifier.RawValue == String {
    func performSegueWithIdentifier(_ segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
                 fatalError("Invalid segue identifier \(segue.identifier ?? "No identifier provided")")
        }
        
        return segueIdentifier
    }
}
