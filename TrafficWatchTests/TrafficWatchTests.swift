//
//  TrafficWatchTests.swift
//  TrafficWatchTests
//
//  Created by Zhechko Zhechev on 11/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import UIKit
import XCTest
import TrafficWatch

class TrafficWatchTests: XCTestCase, IncidentsParserDelegate {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIncidentInit() {
        
        let title = "incident"
        let weblink = "http://test"
        let summary = "summary"
        let incident = Incident(title: title, time: Date.distantPast, weblink: weblink, summary: summary)
        
        XCTAssertTrue(incident.title == title, "title is not correctly initialized")
        XCTAssertTrue(incident.weblink == weblink, "weblink is not correct initialized")
        XCTAssertTrue(incident.summary == summary, "summary is not correct initialized")
    }
    
    func testDescriptionInit() {
        let title = "incident1"
        let weblink = "http://test1"
        let summary = "summary1"
        let incident1 = Incident(title: title, time: Date.distantPast, weblink: weblink, summary: summary)
        let incident2 = Incident(title: title, time: Date.distantPast, weblink: weblink, summary: summary)
        
        let description1 = incident1.description
        let description2 = incident2.description
        
        XCTAssertTrue(description1.range(of: title) != nil, "Titel of incident in the description not found. Description not correctly initialized")
        XCTAssertTrue(description1.range(of: weblink) != nil, "Weblink of incident in the description not found. Description not correctly initialized")
        XCTAssertTrue(description1.range(of: summary) != nil, "Summary of incident in the description not found. Description not correctly initialized")
        XCTAssertTrue(description1 == description2, "Description of two identical Incidents must be equeal")
    }
    
    // MARK: - class variables
    var done = false
    var loadedIncidents = [Incident]()
    let incidentsURLString = "http://www.freiefahrt.info/lmst.de_DE.xml"
    
    // MARK: - helper methods
    func waitForCompletion (_ timeoutSecs: TimeInterval) -> Bool {
        
        let timeoutDate = Date(timeIntervalSinceNow: timeoutSecs)
        
        repeat {
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: timeoutDate)
            if timeoutDate.timeIntervalSinceNow < 0.0 {
                break
            }
        } while (!done)
        
        return done
    }

    // MARK: - Test methods
    // This is the actual test case
    func testOperationParser() {
        // This is an example of a performance test case.
        self.measure() {
            let operationQueue = OperationQueue()
            let parseOperation = IncidentsParseOperation(feedURL: URL(string: self.incidentsURLString)!,
                delegate: self)
                
            operationQueue.addOperation(parseOperation)
                
            // Wait for completion
            XCTAssertTrue(self.waitForCompletion(90.0), "Failed to get any results in time")
            // Test whether your received results are valid
            print("\(self.loadedIncidents.count) incidents were loaded" )
            XCTAssertTrue(self.loadedIncidents.count > 0, "No incident was loaded")
        }
    }

    // MARK: - delegate methods on the background thread
    func incidentsParseOperation(_ parseOperation: IncidentsParseOperation,
                                 loadedIncidents: [Incident], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.handleLoadedIncidents(loadedIncidents)
        }
    }
    
    // MARK: - synchronization method on the main thread
    func handleLoadedIncidents (_ loadedIncidents: [Incident]) {
            self.loadedIncidents = loadedIncidents
            self.done = true
    }
}
