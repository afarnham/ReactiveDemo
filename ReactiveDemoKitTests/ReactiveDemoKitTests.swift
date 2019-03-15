//
//  ReactiveDemoKitTests.swift
//  ReactiveDemoKitTests
//
//  Created by Raymond Farnham on 2/27/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import XCTest
import SnapshotTesting
import ReactiveSwift
import Result
import CoreLocation
import Overture
@testable import ReactiveDemoKit

class ReactiveDemoKitTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testViewModelOutput() {
        let testDate = Date()
        let testLoc = CLLocation(latitude: 29.95, longitude: -96)
        let testName = "KSGR"
        let testMetar = "Test Metar"
        let testAirport = FlightComputer.Airport(name: testName,
                                                 coordinate: CLLocationCoordinate2DMake(29.95, -96),
                                                 metar: testMetar)
        
        let (viewDidLoadSignal, _) = Signal<Void, NoError>.pipe()
        let (flightComputerUpdatedSignal, fcuSink) = Signal<Void, NoError>.pipe()
        let (refreshButtonSignal, _) = Signal<Void, NoError>.pipe()
        
        let (nearest, metar, coordinate) = viewModel(viewDidLoad: viewDidLoadSignal,
                                                     flightComputerUpdated: flightComputerUpdatedSignal,
                                                     refreshButtonPressed: refreshButtonSignal)
        
        nearest.observeValues { (nearest) in
            print("Observed nearest")
            XCTAssertEqual(nearest, testName)
        }
        
        metar.observeValues { (metar) in
            XCTAssertEqual(metar, testMetar)
        }
        
        coordinate.observeValues { (loc) in
            XCTAssertEqual(loc.coordinate.latitude, testLoc.coordinate.latitude)
            XCTAssertEqual(loc.coordinate.longitude, testLoc.coordinate.longitude)
        }
        
        Current.flightComputer = FlightComputer(currentLocation: testLoc,
                                                nearestAirportUpdated: testDate,
                                                nearestAirport: testAirport)

        fcuSink.send(value: ())
    }
    
    
    func testMetarUpdateSnapshot() {
        let testDate = Date()
        let testLoc = CLLocation(latitude: 29.95, longitude: -96)
        let testName = "KSGR"
        let testMetar = "Test Metar"
        let testAirport = FlightComputer.Airport(name: testName,
                                                 coordinate: CLLocationCoordinate2DMake(29.95, -96),
                                                 metar: testMetar)
        
        Current.flightComputer = FlightComputer(currentLocation: testLoc,
                                                nearestAirportUpdated: testDate,
                                                nearestAirport: testAirport)

        let vc = ViewController()
//        record = true
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
        
        #if targetEnvironment(simulator)
        Current.flightComputerService.forceUpdate()
        assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
        #endif
    }
}
