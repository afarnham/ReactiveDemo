//
//  ViewController.swift
//  ReactiveDemo
//
//  Created by Raymond Farnham on 3/3/19.
//  Copyright © 2019 ForeFlight. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveSwift
import ReactiveCocoa
import Result
import Overture
import MapKit

private let UNKNOWN_TEXT = "Unknown"
func viewModel(
    viewDidLoad: Signal<Void, NoError>,
    flightComputerUpdated: Signal<Void, NoError>,
    refreshButtonPressed: Signal<Void, NoError>
) -> (
    nearestAirportText: Signal<String, NoError>,
    metarText: Signal<String, NoError>
) {
  
    let initialAirportText = viewDidLoad.map{ UNKNOWN_TEXT }
    let initialMetarText = viewDidLoad.map { UNKNOWN_TEXT }
    
    let nearestAirport = flightComputerUpdated
        .flatMap(.latest) {
            .init(value: Current.flightComputer.nearestAirport)
        }.merge(with:
            refreshButtonPressed
                .flatMap(.latest) { _ in
                    Current.flightComputer.currentLocation.map {
                        Current.flightComputerService.refreshNearestAirport($0).map { a in Optional(a) }
                        } ?? .init(value: nil)
                }
                .flatMapError { _ in .empty }
        )
    
    let locText = initialAirportText.merge(with:
        nearestAirport.map { $0?.name ?? UNKNOWN_TEXT }
    )
    
    let wxText = initialMetarText
        .merge(with:
            nearestAirport.map { $0?.metar ?? UNKNOWN_TEXT }
        )

    return (locText, wxText)
}

public class ViewController: UIViewController, MKMapViewDelegate {
    let metarLabel: UILabel = with(UILabel(),
                                   metarLabelStyle)
    
    let airportLabel: UILabel = with(UILabel(),
                                     airportLabelStyle)
    

    let refreshButton: UIButton = with(UIButton(type: .system),
                                       autoLayoutStyle)
    
    let mapView: MKMapView = with(MKMapView(frame: .zero),
                                  autoLayoutStyle)
    
    fileprivate let viewDidLoadProperty = MutableProperty(())

    public override func loadView() {
        self.view = with(UIView(frame: .zero),
                         mut(\.backgroundColor, .white))
        
        self.view.addSubview(airportLabel)
        self.view.addSubview(metarLabel)
        self.view.addSubview(mapView)
        self.view.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            airportLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            airportLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            airportLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),

            metarLabel.topAnchor.constraint(equalTo: airportLabel.bottomAnchor, constant: 5),
            metarLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            metarLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            
            mapView.topAnchor.constraint(equalTo: metarLabel.bottomAnchor, constant: 5),
            mapView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            
            
            refreshButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 5),
            refreshButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            refreshButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            refreshButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            ])
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        refreshButton.setTitle("Refresh", for: .normal)
        
        bindViewModel()
        viewDidLoadProperty.value = ()
    }
    
    func bindViewModel() {
        let (nearest, metar) = viewModel(
            viewDidLoad: viewDidLoadProperty.signal,
            flightComputerUpdated: Current.flightComputerService.flightComputerUpdatedSignal,
            refreshButtonPressed: refreshButton.reactive.controlEvents(.touchUpInside).map(value: ()))
        
        metarLabel.reactive.text <~ metar
        airportLabel.reactive.text <~ nearest
    }

    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
}

