//
//  LocationProviding.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Result

public struct LocationProviding<T> {
    var start: (T) -> ()
    var stop: (T) -> ()
    var signal: (T) -> Signal<CLLocation, NoError>
    var last: (T) -> CLLocation?
}


extension LocationProviding where T == CoreLocationProvider {
    static let coreLocation = LocationProviding(
        start: { $0.start() },
        stop: { $0.stop() },
        signal: { $0.signal },
        last: { $0.last() }
    )
}

extension LocationProviding where T == MockLocationProvider {
    static let mockLocationProvider = LocationProviding(
        start: { $0.start() },
        stop: { $0.stop() },
        signal: { $0.signal },
        last: { $0.last() }
        
    )
}
