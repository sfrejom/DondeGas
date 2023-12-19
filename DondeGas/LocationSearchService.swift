//
//  LocationSearchService.swift
//  DondeGas
//
//  Created by Sergio Frejo on 14/12/23.
//

import Foundation
import MapKit

class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let searchCompleter = MKLocalSearchCompleter()
    var onUpdate: (([MKLocalSearchCompletion]) -> Void)?

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0, longitude: -3.0),
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        )
        searchCompleter.region = region
    }

    func updateSearch(text: String) {
        searchCompleter.queryFragment = text
    }

    // MKLocalSearchCompleterDelegate methods
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate?(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Manejar errores aquí
    }
}
