//
//  CoreLocationProvider.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Result

//enum LocationAuthAction {
//    case askPermission
//    case notifyDisabled
//}

public class CoreLocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = CoreLocationProvider()
    public let (signal,sink) = Signal<CLLocation, NoError>.pipe()
    
    let locationManager = CLLocationManager()
    
    func start(){
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            locationManager.requestAlwaysAuthorization()
        case .denied:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        }
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func last() -> CLLocation? {
        return locationManager.location
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { (location) in
            sink.send(value: location)
        }
    }
}
