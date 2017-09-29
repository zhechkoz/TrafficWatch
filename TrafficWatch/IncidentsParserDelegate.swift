//
//  IncidentsParserDelegate.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 11/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import Foundation

public protocol IncidentsParserDelegate: class {
    func incidentsParseOperation(_ parseOperation: IncidentsParseOperation, loadedIncidents: [Incident], error: Error?)
}
