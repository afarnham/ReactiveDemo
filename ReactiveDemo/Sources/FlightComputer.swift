//
//  FlightComputer.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import ReactiveSwift
import Result
import Overture

let locDeltaThresholdMeters: CLLocationDistance = 10000
let nearestAirportDeltaThresholdMeters: CLLocationDistance = 15000

public struct FlightComputer {
    public struct Airport {
        public var name: String
        public var coordinate: CLLocationCoordinate2D
        public var metar: String
    }
    
    public var currentLocation: CLLocation?
    public var nearestAirportUpdated: Date?
    public var nearestAirport: Airport?    
}

extension FlightComputer.Airport {
    public init(_ name: String, _ coordinate: CLLocationCoordinate2D, _ metar: String) {
        self.name = name
        self.coordinate = coordinate
        self.metar = metar
    }
    
    public init(_ name: String, _ latitude: Double, _ longitude: Double, _ metar: String) {
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.metar = metar
    }
}

extension FlightComputer {
}

func shouldUpdateNearestAirport(flightComputer: FlightComputer, location: CLLocation) -> Bool {
    let recentlyUpdated = flightComputer.nearestAirportUpdated.map {
        return location.timestamp.timeIntervalSince1970 - $0.timeIntervalSince1970 > 60
        } ?? true

    return recentlyUpdated
}

public class FlightComputerService {
    private var locObsDisposable: Disposable? = nil
    private var refreshNearestDisposable: Disposable? = nil
    public let flightComputerUpdatedSignal: Signal<Void, NoError>
    private let sink: Signal<Void, NoError>.Observer
    
    public init() {
        let (signal, fcSink) = Signal<Void, NoError>.pipe()
        flightComputerUpdatedSignal = signal
        sink = fcSink
    }
    
    func start(locationSignal: Signal<CLLocation, NoError>) {
        locObsDisposable = locationSignal.observeValues(updateFlightComputer(_:))
    }
    
    public func refreshNearestAirport(_ location: CLLocation) -> SignalProducer<FlightComputer.Airport, APIError> {
        return Action<CLLocation, FlightComputer.Airport, APIError> { actionLocation in
            Current.foreflight.fetchNearestAirport(actionLocation.coordinate)
                .flatMap(.latest) { airport in
                    Current.foreflight.fetchMetar(airport.name).map { metar -> FlightComputer.Airport in
                        with(airport, mut(\FlightComputer.Airport.metar, metar))
                    }
                }
        }
        .apply(location)
        .mapError(apiErrorForActionError)
    }
    
    private func updateFlightComputer(_ location: CLLocation) {
        Current.flightComputer = with(Current.flightComputer,
                                      mut(\.currentLocation, location))
        
        guard
            refreshNearestDisposable == nil, //Only allow one request at a time
            shouldUpdateNearestAirport(flightComputer: Current.flightComputer, location: location)
        else { return }
        
        refreshNearestDisposable = refreshNearestAirport(location)
            .startWithResult { result in
                switch result {
                case let .success(airport):
                    Current.flightComputer = with(Current.flightComputer,
                                                  concat(mut(\.nearestAirport, airport),
                                                         mut(\.nearestAirportUpdated, Current.date())))
                    self.sink.send(value: ())
                case let .failure(error):
                    print("\(#function) - ERROR: \(error)")
                }
                self.refreshNearestDisposable?.dispose()
                self.refreshNearestDisposable = nil
        }
    }
    
    #if targetEnvironment(simulator)
    public func forceUpdate() {
        sink.send(value: ())
    }
    #endif
}
