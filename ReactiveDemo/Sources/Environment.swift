//
//  Environment.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Result

public var Current = Environment()

public struct Environment {
    public var calendar = Calendar.autoupdatingCurrent
    public var date = { Date() }
    public var locale = Locale.autoupdatingCurrent
    public var timeZone = TimeZone.autoupdatingCurrent
    public var location: AnyLocationProvider = AnyLocationProvider.coreLocation()
    public var foreflight = ForeFlightClient()
    public var flightComputer = FlightComputer()
    public var flightComputerService = FlightComputerService()
    
    public init() {}
}
