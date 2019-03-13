//
//  MockLocationProvider.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import Result
import ReactiveSwift
import CoreLocation
import MapKit

public class MockLocationProvider {
    let (signal, sink) = Signal<CLLocation, NoError>.pipe()
    var lastLocation: CLLocation? = nil
    var enabled: Bool = false
    let updateRate: Double = 1.0
    var generator: () -> CLLocation
    
    public static func oneMeterPerSecondLocationProvider(initial: CLLocationCoordinate2D) -> MockLocationProvider {
        return MockLocationProvider(locationGenerator: generate1mpsLocations(initial: initial))
    }
    
    public static func alwaysLocationProvider(initial: CLLocationCoordinate2D) -> MockLocationProvider {
        return MockLocationProvider(locationGenerator: alwaysLocation(coordinate: initial))
    }

    private init(locationGenerator: @escaping () -> CLLocation) {
        generator = locationGenerator
    }
    
    func generate() {
        if enabled {
            let generatedLocation = generator()
            lastLocation = generatedLocation
            sink.send(value: generatedLocation)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + updateRate) {
                if self.enabled {
                    self.generate()
                }
            }
        }
    }
    
    func start() {
        enabled = true
        generate()
    }
    
    func stop() {
        enabled = false
    }
    
    func last() -> CLLocation? {
        return lastLocation
    }
}

func alwaysLocation(coordinate: CLLocationCoordinate2D) -> () -> CLLocation {
    return {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

func generateRandomLocation() -> CLLocation {
    let x = Double.random(in: 0..<MKMapRect.world.size.width)
    let y = Double.random(in: 0..<MKMapRect.world.size.height)
    let coord = MKMapPoint(x: x, y: y).coordinate
    return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
}

func generate1mpsLocations(initial: CLLocationCoordinate2D) -> () -> CLLocation {
    return generateEquidistantLocations(initial: initial, metersDistance: 1)
}


func generateEquidistantLocations(initial: CLLocationCoordinate2D, metersDistance: Double) -> () -> CLLocation {
    let pointsPerMeter = MKMapPointsPerMeterAtLatitude(initial.latitude)
    let initialPoint = MKMapPoint(initial)
    var count = 0
    
    let genLocation: (MKMapPoint, Double) -> CLLocation = { startPoint, meters in
        let nextPoint = MKMapPoint(x: startPoint.x + pointsPerMeter * meters,
                                   y: startPoint.y)
        return CLLocation(coordinate: nextPoint.coordinate,
                          altitude: 0,
                          horizontalAccuracy: 1,
                          verticalAccuracy: 1,
                          course: 0,
                          speed: metersDistance,
                          timestamp: Date())
    }
    
    return {
        let nextLocation = genLocation(initialPoint, Double(count) * metersDistance)
        count = count + 1
        return nextLocation
    }
}
