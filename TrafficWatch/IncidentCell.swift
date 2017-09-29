//
//  IncidentCell.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 12/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import UIKit

final class IncidentCell: UITableViewCell {
    @IBOutlet weak fileprivate var titleLabel: UILabel!
    @IBOutlet weak fileprivate var descriptionLabel: UILabel!
    @IBOutlet weak var signImage: UIImageView!

    func configure(_ incident: Incident) {
        titleLabel.text = incident.title
        descriptionLabel.text = incident.summary
        
        // Load image if provided
        if let image = incident.image {
            signImage.image = image
        } else {
            // Make sure image is not set
            signImage.image = nil
        }
    }
}
