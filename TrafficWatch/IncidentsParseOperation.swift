//
//  IncidentsParser.swift
//  TrafficWatch
//
//  Created by Zhechko Zhechev on 11/10/14.
//  Copyright (c) 2014 LS1 TUM. All rights reserved.
//

import Foundation
import CoreLocation

final public class IncidentsParseOperation: Operation, XMLParserDelegate {
    
    fileprivate var currentIncidentObject: Incident?
    fileprivate var contentOfCurrentIncidentString: String?
    
    weak var delegate: IncidentsParserDelegate?
    
    fileprivate var feedURL: URL
    fileprivate var parsedIncidentObjects: [Incident]!
    
    public init(feedURL: URL, delegate: IncidentsParserDelegate) {
        self.feedURL = feedURL
        self.delegate = delegate
        super.init()
    }
    
    override public func main() {
        parsedIncidentObjects = [Incident]()
        var successful = false
        var error: Error?
        
        if let parser = XMLParser(contentsOf: feedURL) {
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.shouldReportNamespacePrefixes = false
            parser.shouldResolveExternalEntities = false
            
            successful = parser.parse()

            if !successful || isCancelled {
                parsedIncidentObjects = []
                error = parser.parserError
            }
        }
        delegate?.incidentsParseOperation(self, loadedIncidents: parsedIncidentObjects, error: error)
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        
        let tempElementName = qName ?? elementName
        
        switch tempElementName {
        case "item":
            // Found the start of a incident
            currentIncidentObject = Incident()
            
        case "link":
            let relAtt = attributeDict["rel"]
            if currentIncidentObject != nil && relAtt == "alternate" {
                let link = attributeDict["href"]
                currentIncidentObject!.weblink = link!
                currentIncidentObject!.location = locationFromString(link!) // Parse link to take location
            }
            
        case "img":
            let srcAtt = attributeDict["src"]
            if currentIncidentObject != nil && currentIncidentObject?.imageURL == nil {
                let url = URL(string: srcAtt!)
                currentIncidentObject?.imageURL = url
            }
            
        case "updated":
            contentOfCurrentIncidentString = String()
            
        case "title":
            // Found title of accident
            contentOfCurrentIncidentString = String()
            
        case "description":
            // Found summary for accident
            contentOfCurrentIncidentString = String()
            
        default:
            // Don't care
            contentOfCurrentIncidentString = nil
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if contentOfCurrentIncidentString != nil { // Something useful has been found
            contentOfCurrentIncidentString = contentOfCurrentIncidentString! + string
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        let tempElementName = qName ?? elementName
        
        if currentIncidentObject != nil { // Because in xml are other tags "title"
            switch tempElementName {
            case "item":
                parsedIncidentObjects.append(currentIncidentObject!)
                currentIncidentObject = nil
                
            case "title":
                currentIncidentObject!.title = contentOfCurrentIncidentString
                
            case "description":
                currentIncidentObject!.summary = contentOfCurrentIncidentString ?? ""
                
            case "link":
                currentIncidentObject!.weblink = contentOfCurrentIncidentString ?? ""
                
            case "updated":
                currentIncidentObject!.time = dateFromString(contentOfCurrentIncidentString ?? "")
                
            default:
                return
            }
        }
    }
    
    fileprivate func locationFromString(_ locationString: String) -> CLLocation? {
        
        // Makes a regex for lon=NUMBERS&lat=NUMBERS pattern
        let pattern = "lon=(\\d*\\.\\d*)&lat=(\\d*\\.\\d*)"
	
        guard let regEx = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
			let ranges = regEx.firstMatch(in: locationString, options: [],
			                              range: NSRange(location: 0, length: locationString.characters.count)) else {
											return nil // Location not found 
		}
		
		let string = locationString as NSString
		
        // If regex found extract values
		let longitudeString = string.substring(with: ranges.range(at: 1))
		let latitudeString = string.substring(with: ranges.range(at: 2))

		guard let longitude = Double(longitudeString),
			let latitude = Double(latitudeString) else {
				return nil
		}

		// Make location
		return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    fileprivate func dateFromString(_ string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter.date(from: string)!
    }
}
