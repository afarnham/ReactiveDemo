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

class AirplaneAnnotationView: MKAnnotationView {
    static let reuseId = "marker-airplane"
    private var lastCoord: CLLocationCoordinate2D? = nil
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.image = UIImage(named: "marker-airplane")
        self.isEnabled = false
        self.canShowCallout = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func update(coordinate: CLLocationCoordinate2D) {
//        guard let lastC = lastCoord else {
//            lastCoord = coordinate
//            return
//        }
//        
//        let lat1InRad = lastC.latitude * Double.pi/180
//        let lat2InRad = coordinate.latitude * Double.pi/180
//        //let fromLon = lastC.longitude * Double.pi/180
//
//        let longitudeDifferenceInRad = (coordinate.longitude - lastC.longitude) * Double.pi/180
//        
//        let y = sin(longitudeDifferenceInRad) * cos(lat2InRad);
//        let x = cos(lat1InRad) * sin(lat2InRad) -
//            sin(lat1InRad) * cos(lat2InRad) * cos(longitudeDifferenceInRad)
//        
//        var bearing = atan2(y, x)
//        
//        bearing = bearing + 2 * Double.pi;
//        if bearing > (2 * Double.pi) {
//            bearing -= (2 * Double.pi)
//        }
//        self.transform = CGAffineTransform(rotationAngle: CGFloat(bearing))
//        
//        lastCoord = coordinate
//    }
}

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
    
    let location = Current.location.signal()

    return (locText, wxText, location)
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
    
    let airplaneAnnotation = MKPointAnnotation()
    
    var locationObserver: Disposable? = nil
    
    var mapViewFinishedRendering: Bool = false
    
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
        //mapView.showsUserLocation = true
        mapView.register(AirplaneAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: AirplaneAnnotationView.reuseId)
        mapView.addAnnotation(airplaneAnnotation)
        
        refreshButton.setTitle("Refresh", for: .normal)
        
        bindViewModel()
        viewDidLoadProperty.value = () //Signal to the view model that the view did load. This property is bound to the viewModel viewDidLoad: input in the bindViewModel() method
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let anView = mapView.dequeueReusableAnnotationView(withIdentifier: AirplaneAnnotationView.reuseId)
        return anView
    }
    
    public func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        mapViewFinishedRendering = fullyRendered
    }
    
    func bindViewModel() {
        let (nearest, metar, location) = viewModel(
            viewDidLoad: viewDidLoadProperty.signal,
            flightComputerUpdated: Current.flightComputerService.flightComputerUpdatedSignal,
            refreshButtonPressed: refreshButton.reactive.controlEvents(.touchUpInside).map(value: ()))
        
        metarLabel.reactive.text <~ metar
        airportLabel.reactive.text <~ nearest
        locationObserver = location.observeValues({ (location) in
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            DispatchQueue.main.async {
                self.mapView.setRegion(self.mapView.regionThatFits(region), animated: true)
                self.airplaneAnnotation.coordinate = location.coordinate
//                if let anView = self.mapView.view(for: self.airplaneAnnotation) as? AirplaneAnnotationView {
//                    anView.update(coordinate: location.coordinate)
//                }
            }
            
        })
    }
}

