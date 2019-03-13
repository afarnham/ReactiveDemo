import UIKit
import PlaygroundSupport
import ReactiveSwift
import ReactiveCocoa
import Result
import ReactiveDemoKit
import Overture
import CoreLocation

let button = UIButton(type: .system)

func fireButton(_ count: Int = 0, updateInterval: Double = 1) {
    if count < 5 {
        button.sendActions(for: .touchUpInside)
        DispatchQueue.main.asyncAfter(deadline: .now() + updateInterval) {
            fireButton(count + 1)
        }
    }
}

let buttonSignal = button.reactive.controlEvents(.touchUpInside)

//PART 1 - Reactive Button signal

//
//
//let disposable = buttonSignal.observeValues { _ in
//    print("BUTTON FIRED")
//}
//
//fireButton()

//PART 2 Bind signal to UI

//let textField = UITextField()
//
//var count = 0
//
//buttonSignal.observeValues { _ in count += 1 }
//
//let buttonPressedCountSignal = buttonSignal.map { _ in "Button Press Count: \(count)" }
//textField.reactive.text <~ buttonPressedCountSignal
//
//let kvoObserver = textField.observe(\.text) { (kvotextfield, change) in
//    print("KVO OUTPUT: \(kvotextfield.text ?? "NIL TEXT")")
//}
//
//fireButton()


//PART 3 Merged Button & Location Signals

//Current = with(Current,
//               mut(\.location,
//                   AnyLocationProvider.mockEquidistantLocationProvider()))
//Current.location.start()
//
//let locSignal = Current.location.signal().map { $0.coordinate }
//
//let mergedSignal = buttonSignal
//    //.map { _ in Current.location.last()?.coordinate ?? kCLLocationCoordinate2DInvalid }
//    .map { _ in kCLLocationCoordinate2DInvalid }
//    .merge(with: locSignal)
//
//let dispose = mergedSignal.observeValues { (coord) in
//    print("-------------")
//    if CLLocationCoordinate2DIsValid(coord) {
//        print("LOCATION PROVIDER FIRED: \(coord)")
//    } else {
//        print("BUTTON FIRED: \(coord)")
//    }
//}
//
//fireButton(updateInterval: 0.8) //offset from the location updates

//PART 4 - Bind merged signal to UI

//let textField = UITextField()
//
//let kvoObserver = textField.observe(\.text) { (kvotextfield, change) in
//    print("KVO OUTPUT: \(kvotextfield.text ?? "NIL TEXT")")
//}
//textField.reactive.text <~ mergedSignal.map { "LAT: \($0.latitude) - LON: \($0.longitude) "}
//
//fireButton()


//PART 5 - Functional transformations

//let departure = Property<String>(value: "KIAH")
//let destination = Property<String>(value: "KAUS")
//let route = Property<String>(value: "BNDTO5 BNDTO IDU.BITER8")
//
//struct Flight {
//    let departure: String
//    let destination: String
//    let route: String
//}


PlaygroundPage.current.needsIndefiniteExecution = true
