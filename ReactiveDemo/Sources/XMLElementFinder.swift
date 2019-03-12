//
//  XMLElementFinder.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation

final class XMLElementFinder: NSObject, XMLParserDelegate {
    let parser: XMLParser
    var elementsToSearch: [String]
    var completedElements = [String]()
    var startedElement: String? = nil
    var values: [String : String] = [:]
    let callback: ([String : String]) -> ()
    
    init(data: Data, elementNames: [String], callback: @escaping ([String : String]) -> ()) {
        parser = XMLParser(data: data)
        
        elementsToSearch = elementNames
        self.callback = callback
        super.init()
        parser.delegate = self
        
    }
    
    func start() {
        parser.parse()
    }
    func parserDidStartDocument(_ parser: XMLParser) {
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementsToSearch.contains(elementName) {
            startedElement = elementName
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let elementName = startedElement {
            if var v = values[elementName] {
                v.append(string)
                values[elementName] = v
            } else {
                values[elementName] = string
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let element = startedElement, element == elementName {
            elementsToSearch.removeAll { (e) -> Bool in
                e == element
            }
            completedElements.append(element)
            if elementsToSearch.count == 0 {
                values = values.mapValues { (v) -> String in
                    let tokens = v.split(separator: " ")
                    return tokens[0].trimmingCharacters(in: .whitespacesAndNewlines)
                }
                callback(values)
                parser.abortParsing()
            }
        }
    }
}
