import UIKit
import PlaygroundSupport
import ReactiveSwift
import ReactiveCocoa
import Result
import ReactiveDemoKit
import Overture
import CoreLocation

let button = UIButton(type: .system)

func fireButton(_ count: Int = 0, updateInterval: Double = 1, numIterations: Int = 5) {
    if count < numIterations {
        button.sendActions(for: .touchUpInside)
        DispatchQueue.main.asyncAfter(deadline: .now() + updateInterval) {
            fireButton(count + 1, updateInterval: updateInterval, numIterations: numIterations)
        }
    }
}

//Get a signal for the button for standard iOS touch up inside events
let buttonSignal = button.reactive.controlEvents(.touchUpInside)

//PART 1 - Reactive Button signal

//let disposable = buttonSignal.observeValues { _ in
//    print("BUTTON FIRED")
//}
//
//fireButton()

//PART 2 Bind signal to UI

//let label = UILabel()
//
//var count = 0
//
////Here is how we catch events
//buttonSignal.observeValues { _ in count += 1 }
//
////Transform the button events to a more useful output for the UILabel
//let buttonPressedCountSignal = buttonSignal.map { _ in "Button Press Count: \(count)" }
//
////Bind to the UI
//label.reactive.text <~ buttonPressedCountSignal
//
//
////KVO is a standard iOS API - not ReactiveSwift related, though the Swift implementation seems to have taken cues from Reactive programming in it's implementation
//let kvoObserver = label.observe(\.text) { (kvolabel, change) in
//    print("KVO OUTPUT: \(kvolabel.text ?? "NIL TEXT")")
//}
//
//fireButton()


//PART 3 Merged Button & Location Signals

////For now just think of Current as a means for providing geographic locations update events to our environment via a ReactiveSwift Signal
//Current.location = AnyLocationProvider.mockEquidistantLocationProvider() //This location provider moves east on a latitude at 1 meter per second
//
//Current.location.start()
//
////Map the CLLocation object in the signal to CLLocationCoordinate2D
//let locSignal = Current.location.signal().map { $0.coordinate }
//
////Merge button fire signal and location update signal into 1 signal
////Have to make the value types from both signals match in order to merge so map the button to a coordinate value
//let mergedSignal = buttonSignal
//    .map { _ in kCLLocationCoordinate2DInvalid } //When the button fires, we return an invalid geo coord
//    .merge(with: locSignal)
//
//let dispose = mergedSignal.observeValues { (coord) in
//    print("-------------")
//    if CLLocationCoordinate2DIsValid(coord) { //Valid coord, then it was the location provider that evented the value
//        print("LOCATION PROVIDER FIRED: \(coord)")
//    } else { //invalid coord, then it was the button that evented the value
//        print("BUTTON FIRED: \(coord)")
//    }
//}
//
//fireButton(updateInterval: 0.8) //offset button updates from the location updates

//PART 4 - Bind merged signal to UI

//let label = UILabel()
//
//let kvoObserver = label.observe(\.text) { (kvolabel, change) in
//    print("KVO OUTPUT: \(kvolabel.text ?? "NIL TEXT")")
//}
//label.reactive.text <~ mergedSignal.map { "LAT: \($0.latitude) - LON: \($0.longitude) "}
//
//fireButton()

//PART 5 - Functional transforms

//Current.location = AnyLocationProvider.mockEquidistantLocationProvider()
//Current.location.start()
//
////Map - 1 to 1 transformations
//let latLonSig = Current.location.signal().map {
//    return "MAPPED LOCATION: \($0.coordinate.latitude), \($0.coordinate.longitude)"
//}
//
//let latLonObserver = latLonSig.observeValues { (coordStr) in
//    print(coordStr)
//}

//flatMap - chain operations on a value

//let nearestAirportMetar = buttonSignal
//    //convert the buttonSignal into a SignalProducer (aka cold signal) because the network requests return SignalProducers so we need to operate in the same type
//    .producer
//
//     //mapping the producer to a constant coordinate, but the buttonSignal/producer could be merged with a text field signal that accepts lat/lon to get coords from user input
//    .map { _ in CLLocationCoordinate2DMake(29.984, -95.341) }
//
//     //chain our nearest airport call using our coordinate
//    .flatMap(.latest) { Current.foreflight.fetchNearestAirport($0) }
//
//     //then chain our metar call using our nearest airport ICAO ident
//    .flatMap(.latest) { Current.foreflight.fetchMetar($0.name) }
//
//let observeNearestAirportMetar = Signal<String, APIError>.Observer(
//    value: { (metar) in print(metar)},
//    failed: { error in dump(error) }
//)

//Start our cold signal so it becomes a hot signal that can send events
//let disposable = nearestAirportMetar.start(observeNearestAirportMetar)

//fireButton(updateInterval: 0, numIterations: 1)

//Zip - Combine values contained in signals

//Current.location = AnyLocationProvider.mockEquidistantLocationProvider()
//Current.location.start()
//
//func formatLocationAndMetar(_ location: CLLocation, _ metar: String) -> String {
//    return "\(location.coordinate.latitude), \(location.coordinate.latitude) - \(metar)"
//}
//
//let nearestAirportMetar = buttonSignal
//    .producer
//    .map { _ in CLLocationCoordinate2DMake(29.984, -95.341) }
//    .flatMap(.latest) { Current.foreflight.fetchNearestAirport($0) }
//    .flatMap(.latest) { Current.foreflight.fetchMetar($0.name) }
//
//let zipped = SignalProducer
//    .zip(Current.location.signal().producer.promoteError(APIError.self),
//         nearestAirportMetar)
//    .map { formatLocationAndMetar($0.0, $0.1) }
//
//zipped.startWithResult { (result) in
//    switch result {
//    case .success(let value):
//        print(value)
//    case .failure(let error):
//        dump(error)
//    }
//}
//
//fireButton(updateInterval: 0, numIterations: 1)


//Zip + Map Constructors

//struct DemoAirport {
//    let name: String
//    let coord: CLLocationCoordinate2D
//    let metar: String
//}
//
//extension DemoAirport {
//    init(name: String, lat: Double, lon: Double, metar: String) {
//        self.name = name
//        coord = CLLocationCoordinate2DMake(lat, lon)
//        self.metar = metar
//    }
//}
//
//let name: String? = "KSGR"
//let lat: Double? = 29.95
//let lon: Double? = -95.8
//let metar: String? = "KSGR 150153Z 35007KT 10SM SCT070 BKN250 18/06 A3007 RMK AO2 SLP181 T01830056"
//
////Without zip:
//var ifLetAirport: DemoAirport? = nil
//if let name = name,
//    let lat = lat,
//    let lon = lon,
//    let metar = metar
//{
//    ifLetAirport = DemoAirport(name: name, lat: lat, lon: lon, metar: metar)
//}
//
////With zip(with:)
//
//let zipAirport = zip(with: DemoAirport.init)(name, lat, lon, metar)
//
//print("ifLetAirport: \(ifLetAirport)")
//print("\nzipAirport: \(zipAirport)")

//Zip functions can be written for Signals, Validation types, or even asynchronous operation types, like Parallel below.

//public struct Parallel<A> {
//    public let run: (_ callback: @escaping (A) -> Void) -> Void
//}

//Below is what run above looks like in traditional func definition form. Perhaps a bit easier to visualize what the `run` type signature means in the Parallel struct:
//func run<A>(callback: @escaping (A) -> Void) {
//     //do some asynchronous work in this block and call the callback when done
//}

//struct DemoAirport {
//    let name: String
//    let coord: CLLocationCoordinate2D
//    let metar: String
//}
//
////Helper for printing output
//func parallelStatusMessage(_ msg: String) {
//    print("----------------")
//    print(msg)
//}
//
////Immediate async operation
//let p1 = Parallel<String> { callback in
//    DispatchQueue.global().async {
//        parallelStatusMessage("FINISHED ICAO IDENT")
//        callback("KSGR")
//    }
//}
//
////Immediate async operation
//let p2 = Parallel<CLLocationCoordinate2D> { callback in
//    DispatchQueue.global().async {
//        parallelStatusMessage("FINISHED COORDINATE")
//        callback(CLLocationCoordinate2DMake(29.95, -96))
//    }
//}
//
////5 second delay async operation
//let p3 = Parallel<String> { callback in
//    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//        DispatchQueue.global().async {
//            parallelStatusMessage("FINISHED METAR")
//            callback("METAR")
//        }
//    }
//}
//
//let zipF = zip3(with: DemoAirport.init)
//let p4 = zipF(p1, p2, p3)
//p4.run { v in
//    parallelStatusMessage("Final value from Parallel zip(with:)\n\n\(v)")
//}
//
////zip3(with: FlightComputer.Airport.init)(p1, p2, p3).run { v in
////    parallelStatusMessage("Final value from Parallel zip(with:)\n\n\(v)")
////}

PlaygroundPage.current.needsIndefiniteExecution = true
