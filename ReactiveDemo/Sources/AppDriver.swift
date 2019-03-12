//
//  AppDriver.swift
//  ReactiveDemoKit
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation

public class AppDriver {
    public init() {}
    
    public func bootstrap() {
        Current.location.start()
        Current.flightComputerService.start(locationSignal: Current.location.signal())
    }
}
