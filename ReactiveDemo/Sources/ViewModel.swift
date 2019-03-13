//
//  ViewModel.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/13/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import CoreLocation

private let UNKNOWN_TEXT = "Unknown"
func viewModel(
        viewDidLoad: Signal<Void, NoError>,
        flightComputerUpdated: Signal<Void, NoError>,
        refreshButtonPressed: Signal<Void, NoError>
    ) -> (
        nearestAirportText: Signal<String, NoError>,
        metarText: Signal<String, NoError>,
        coordinate: Signal<CLLocation, NoError>
    ) {
        
        let initialAirportText = viewDidLoad.map{ "\(UNKNOWN_TEXT) Airport" }
        let initialMetarText = viewDidLoad.map { "\(UNKNOWN_TEXT) METAR" }
        
        let nearestAirport = flightComputerUpdated
            .flatMap(.latest) {
                .init(value: Current.flightComputer.nearestAirport)
            }.merge(with:
                refreshButtonPressed
                    .flatMap(.latest) { _ in
                        Current.flightComputer.currentLocation.map { currLocation in
                            Current.flightComputerService.refreshNearestAirport(currLocation)
                                .map { refreshedAirport in Optional(refreshedAirport) }
                            } ?? .init(value: nil) // if no currentLocation on the flightComputer produce a nil value
                    }
                    .flatMapError { _ in .empty } //ignore any errors
        )
        
        let locText = initialAirportText
            .merge(with:
                nearestAirport.map { $0?.name ?? UNKNOWN_TEXT }
        )
        
        let wxText = initialMetarText
            .merge(with:
                nearestAirport.map { $0?.metar ?? UNKNOWN_TEXT }
        )
        
        let location = Current.location.signal()
        
        return (locText, wxText, location)
}
