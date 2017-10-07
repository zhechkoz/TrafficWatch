//
//  Incident.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 11/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

open class Incident: NSObject, MKAnnotation {
    
    open var title: String?
    open var time: Date
    open var summary: String
    open var weblink: String
    open var imageURL: URL?
    open var image: UIImage?
    open var location: CLLocation?
    open var coordinate: CLLocationCoordinate2D {
        return location?.coordinate ?? CLLocationCoordinate2D()
    }
    
    public init(title: String, time: Date, weblink: String, summary: String) {
        self.title = title
        self.time = time
        self.weblink = weblink
        self.summary = summary
    }
    
    public convenience override init() {
        self.init(title: "Unknown Incident", time: Date.distantPast, weblink: "Not available", summary: "Not available")
    }
    
    func getName(_ classType: AnyClass) -> String {
        let classString = NSStringFromClass(classType.self)
		let range = classString.range(of: ".",
            options: .caseInsensitive,
            range: nil,
            locale: nil)

		return String(classString[..<range!.upperBound])
    }
    
    open override var description: String {
        return "<\(getName(Incident.self)): title = \(self.title ?? "No Title"), time = \(time), weblink = \(self.weblink), summary = \(self.summary)>"
    }
}
