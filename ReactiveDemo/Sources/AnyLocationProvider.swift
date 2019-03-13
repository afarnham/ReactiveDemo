//
//  LocationProvider.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Result
import Overture

public struct AnyLocationProvider {
    public var start: () -> ()
    public var stop: () -> ()
    public var signal: () -> Signal<CLLocation, NoError>
    public var last: () -> CLLocation?
    
    private static func create<T>(_ witness: LocationProviding<T>, provider: T) -> AnyLocationProvider {
        return AnyLocationProvider(
            start: { witness.start(provider) },
            stop: { witness.stop(provider) },
            signal: { witness.signal(provider).on(value: { (location) in
                Current.flightComputer = with(Current.flightComputer,
                                              mut(\FlightComputer.currentLocation, location))
                })
            },
            last: { witness.last(provider) }
        )
    }
    
    static func coreLocation() -> AnyLocationProvider {
        return create(LocationProviding.coreLocation, provider: CoreLocationProvider.shared)
    }
    
    public static func mockEquidistantLocationProvider() -> AnyLocationProvider {
        let provider = MockLocationProvider.oneMeterPerSecondLocationProvider(initial: CLLocationCoordinate2DMake(29, -95))
        return create(LocationProviding.mockLocationProvider, provider: provider)
    }
    
    public static func mockAlwaysLocationProvider(coordinate: CLLocationCoordinate2D) -> AnyLocationProvider {
        let provider = MockLocationProvider.alwaysLocationProvider(initial: coordinate)
        return create(LocationProviding.mockLocationProvider, provider: provider)
    }
}
