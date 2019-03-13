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
            }
            
        })
    }
}

