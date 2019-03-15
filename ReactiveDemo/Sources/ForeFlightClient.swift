//
//  ForeFlightClient.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import Foundation
import CoreLocation
import Result
import ReactiveSwift
import Overture

public enum APIError: Error {
    case badResponse(Int?)
    case sessionError(Error)
    case badData(Data?)
    case deserializationError(Error)
    case actionDisabled
    case failedToParseResponse
}

public struct ForeFlightClient {
    public let fetchMetar: (String) -> SignalProducer<String, APIError>
    public let fetchNearestAirport: (CLLocationCoordinate2D) -> SignalProducer<FlightComputer.Airport, APIError>
    
    public init(fetchMetar: @escaping (String) -> SignalProducer<String, APIError>,
                fetchNearestAirport: @escaping (CLLocationCoordinate2D) -> SignalProducer<FlightComputer.Airport, APIError>)
    {
        self.fetchMetar = fetchMetar
        self.fetchNearestAirport = fetchNearestAirport
    }
    
    public init() {
        self.init(fetchMetar: fetchForeFlightMetar,
                  fetchNearestAirport: fetchAvWXGovNearestAirport)
    }
}

func send<A>(result: Result<A, APIError>, observer: Signal<A, APIError>.Observer) {
    switch result {
    case let .success(value):
        _ = observer.send(value: value)
    case let .failure(error):
        _ = observer.send(error: error)
    }

}

func apiErrorForActionError(_ actionError: ActionError<APIError>) -> APIError {
    switch actionError {
    case .disabled:
        return .actionDisabled
    case .producerFailed(let error):
        return error
    }
}

func fetchForeFlightMetar(_ airport: String) -> SignalProducer<String, APIError> {
    return Action<String, String, APIError> { actionAirport in
        .init({ (observer: Signal<String, APIError>.Observer, lifetime) -> Void in
            metar(for: actionAirport) { send(result: $0, observer: observer) }
        })
    }
    .apply(airport)
    .mapError(apiErrorForActionError)
}

func fetchAvWXGovNearestAirport(_ coord: CLLocationCoordinate2D) -> SignalProducer<FlightComputer.Airport, APIError> {
    return Action<CLLocationCoordinate2D, FlightComputer.Airport, APIError> { actionCoord in
        .init({ (observer: Signal<FlightComputer.Airport, APIError>.Observer, lifetime) -> Void in
            nearestAirport(actionCoord, callback: { send(result: $0, observer: observer)} )
        })
    }
    .apply(coord)
    .mapError(apiErrorForActionError)
}

private func dataTask(_ url: URL, _ callback: @escaping (Result<Data, APIError>) -> Void) {
    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: url) { (data, response, error) in
        guard let response = response as? HTTPURLResponse else {
            callback(.failure(.badResponse(nil)))
            return
        }
        
        let statusCode = response.statusCode
        
        guard statusCode == 200 else {
            callback(.failure(.badResponse(statusCode)))
            return
        }
        
        if let error = error {
            callback(.failure(.sessionError(error)))
            return
        }
        
        
        if let data = data {
            callback(.success(data))
        } else {
            callback(.failure(.badData(data)))
        }
    }
    task.resume()

}

private func metar(for airport: String, callback: @escaping (Result<String, APIError>) -> Void) {
    let url = URL(string: "https://api.foreflight.com/weather/report/\(airport)")!
    //dump(url)
    dataTask(url) { dataResult in
        switch dataResult {
        case let .success(data):
            do {
            let metarJsonObj = try JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as? [AnyHashable : Any]
                let metar = metarJsonObj
                    .flatMap { $0["report"] as? [AnyHashable : Any] }
                    .flatMap { $0["conditions"] as? [AnyHashable : Any] }
                    .flatMap { $0["text"] as? String }
                if let metar = metar {
                    callback(.success(metar))
                } else {
                    callback(.failure(.badData(data)))
                }

            } catch let error {
                callback(.failure(.deserializationError(error)))
            }
            
        case let .failure(error):
            callback(.failure(error))
        }
    }
}

private func nearestAirport(_ coord: CLLocationCoordinate2D, callback: @escaping (Result<FlightComputer.Airport, APIError>) -> Void) {
    let urlStr = "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=stations&requestType=retrieve&format=xml&radialDistance=10;\(coord.longitude),\(coord.latitude)"
    //dump(urlStr)
    dataTask(URL(string: urlStr)!) { (dataResult) in
        switch dataResult {
        case let .success(data):
            let finder = XMLElementFinder(data: data, elementNames: ["station_id", "latitude", "longitude"], callback: { values in
                let airport = zip(with: FlightComputer.Airport.init)(
                    values["station_id"],
                    values["latitude"].flatMap { Double($0) },
                    values["longitude"].flatMap { Double($0) },
                    ""
                    )
                if let airport = airport {
                    callback(.success(airport))
                } else {
                    callback(.failure(.failedToParseResponse))
                }
            })
            finder.start()
        case let .failure(error):
            callback(.failure(error))
        }
    }
}
