import Foundation
import CoreLocation
import MapKit
import SwiftUI

final class LocationManager: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: .init(latitude: 40.4165, longitude: -3.70256),
            span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    @Published var region = MKCoordinateRegion()
    @Published var userLocation = MKCoordinateRegion()
    @Published var locationName: String = ""
    
    let UserDefaults = UserDefaultsManager.shared
    
    override init() {
        super.init()
        
        // The center of Madrid is defined as location in case there is no stored location and
        // user location access is disabled
        if UserDefaults.isUsingCustomLocation {
            if let lastCustomLocation = UserDefaults.lastCustomLocation {
                userLocation = lastCustomLocation
            }
        } else {
            userLocation = UserDefaults.lastCustomLocation ?? MKCoordinateRegion (center: CLLocationCoordinate2D(latitude: 40.4167, longitude: -3.70325), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            
            region = MKCoordinateRegion(
                center: .init(latitude: 40.4165, longitude: -3.70256),
                span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.setup()
    }

    private func setup() {
      switch locationManager.authorizationStatus {
      case .authorizedWhenInUse:
        //If we are authorized then we request location just once to center the map
        locationManager.requestLocation()
      //If we don´t, we request authorization
      case .notDetermined:
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
      default:
        break
      }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus == .authorizedWhenInUse else { return }
        
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error obtaining location: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        locations.last.map {
                region = MKCoordinateRegion(
                    center: .init(latitude: $0.coordinate.latitude - 0.006, longitude: $0.coordinate.longitude), 
                    span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            
                withAnimation {
                    userLocation = region
                    mapPosition = .region(region)
                }
            
                UserDefaults.lastCustomLocation = userLocation
            }

        obtainCurrentLocationName() { placemark in
            if let cityName = placemark?.locality {
                self.locationName = cityName
            }
        }
    }
    
    func distanceToGasStation(station gasStation: GasStation) -> Double {
        var stationLocation = CLLocation()
        let currentUserLocation = CLLocation(latitude: self.userLocation.center.latitude, longitude: self.userLocation.center.longitude)
        
        if let stationLatitude = Double(gasStation.latitude.replacingOccurrences(of: ",", with: ".")), let stationLongitude = Double(gasStation.longitude.replacingOccurrences(of: ",", with: ".")) {
            stationLocation = CLLocation(latitude: stationLatitude, longitude: stationLongitude)
        }
        
        // Obtención del resultado en kilómetros
        let kmDistance = stationLocation.distance(from: currentUserLocation) / 1000
        // Con solo dos posiciones decimales
        let decimalCorrection = String(format: "%.2f", kmDistance)
        let result = Double(decimalCorrection.prefix(4)) ?? 0.00
        
        return result
    }
    
    func focusOnUser() {
        withAnimation(.easeInOut(duration: 2.5)) {
            self.region = self.userLocation
            self.mapPosition = MapCameraPosition.region(self.userLocation)
        }
    }
    
    func setLocation(latitude: String, longitude: String) {
        if let lat = Double(latitude.replacing(",", with: ".")), let long = Double(longitude.replacing(",", with: ".")) {
            withAnimation(.easeInOut(duration: 2.5)) {
                self.region = MKCoordinateRegion(
                    center: .init(latitude: lat - 0.006, longitude: long),
                    span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                
                self.mapPosition = MapCameraPosition.region(
                    MKCoordinateRegion(
                        center: .init(latitude: lat - 0.006, longitude: long),
                        span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
        }
    }
    
    func setLocation(latitude: Double, longitude: Double) {
        withAnimation(.easeInOut(duration: 2.5)) {
            self.region = MKCoordinateRegion(
                center: .init(latitude: latitude - 0.006, longitude: longitude),
                span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            
            self.mapPosition = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: .init(latitude: latitude - 0.006, longitude: longitude),
                    span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }
    
    func setRealUserLocation() {
        locationManager.requestLocation()
    }

    func setCustomUserLocation(target: MKLocalSearchCompletion) {
        searchForLocation(using: target) { [weak self] coordinate in
            guard let self = self, let coordinate = coordinate else {
                print("No se pudo obtener las coordenadas.")
                return
            }

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 2.5)) {
                    self.userLocation = MKCoordinateRegion(
                        center: .init(latitude: coordinate.latitude - 0.006, longitude: coordinate.longitude),
                        span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    self.focusOnUser()
                }
                
                self.UserDefaults.lastCustomLocation = self.userLocation

                self.obtainCurrentLocationName { placemark in
                    if let cityName = placemark?.locality {
                        self.locationName = cityName
                    }
                }
            }
        }
    }
    
    private func obtainCurrentLocationName(completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        let userLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        
        geocoder.reverseGeocodeLocation(userLocation, completionHandler: { (placemarks, error) in
                if let error = error {
                    print("Error en la geocodificación inversa: \(error)")
                    completion(nil)
                    return
                }

                guard let placemark = placemarks?.first else {
                    print("No se encontraron placemarks.")
                    completion(nil)
                    return
                }

                completion(placemark)
            })
    }

    func searchForLocation(using suggestion: MKLocalSearchCompletion, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: suggestion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { (response, error) in
            guard error == nil else {
                print("Error en la búsqueda: \(error!.localizedDescription)")
                completion(nil)
                return
            }

            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("No se encontraron coordenadas.")
                completion(nil)
                return
            }

            completion(coordinate)
        }
    }
    
}
