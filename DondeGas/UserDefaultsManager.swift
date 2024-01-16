//
//  UserDefaultsManager.swift
//  DondeGas
//
//  Created by Sergio Frejo on 29/12/23.
//

import Foundation
import MapKit
import Security


class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private init() {}

    // UserDefaults keys
    private let isUsingCustomLocationKey = "isUsingCustomLocation"
    private let lastCustomLocationKey = "lastCustomLocation"
    private let userDefinedRangeKey = "userDefinedRange"
    private let selectedFuelTypeKey = "selectedFuelType"
    private let wasTutorialShownKey = "wasTutorialShown"
    
    var wasTutorialShown: Bool {
        get { UserDefaults.standard.bool(forKey: wasTutorialShownKey) }
        set { UserDefaults.standard.set(newValue, forKey: wasTutorialShownKey) }
    }

    var isUsingCustomLocation: Bool {
        get { UserDefaults.standard.bool(forKey: isUsingCustomLocationKey) }
        set { UserDefaults.standard.set(newValue, forKey: isUsingCustomLocationKey) }
    }

    var lastCustomLocation: MKCoordinateRegion? {
        get { self.loadRegion()}
        set { self.saveRegion(newValue) }
    }

    var userDefinedRange: Int {
        get { UserDefaults.standard.integer(forKey: userDefinedRangeKey) }
        set { UserDefaults.standard.set(newValue, forKey: userDefinedRangeKey) }
    }

    var selectedFuelType: FuelType? {
        get {
            guard let data = UserDefaults.standard.data(forKey: selectedFuelTypeKey),
                  let fuelType = try? JSONDecoder().decode(FuelType.self, from: data) else {
                return nil
            }
            return fuelType
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: selectedFuelTypeKey)
            }
        }
    }
}

extension UserDefaultsManager {
    /*
     * The user location is stored on the keychain instead of UserDefaults. This way, the information is stored
     * encrypted, which is safer.
     */
    func saveRegion(_ region: MKCoordinateRegion?) {
        if let region = region {
            saveToKeychain(region: region)
        } else {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.sfrejom.dondegas",
                kSecAttrAccount as String: "lastCustomLocation"
            ]
            SecItemDelete(query as CFDictionary)
        }
    }


    func loadRegion() -> MKCoordinateRegion? {
        return loadFromKeychain()
    }
    
    func saveToKeychain(region: MKCoordinateRegion) {
        let regionData: [String: CLLocationDegrees] = [
            "latitude": region.center.latitude,
            "longitude": region.center.longitude,
            "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: regionData, options: [])
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.sfrejom.dondegas",
                kSecAttrAccount as String: "lastCustomLocation",
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary) // Elimina cualquier item existente
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else { return }
        } catch {
            print("Error al serializar la región")
        }
    }

    
    func loadFromKeychain() -> MKCoordinateRegion? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sfrejom.dondegas",
            kSecAttrAccount as String: "lastCustomLocation",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        
        do {
            if let regionData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: CLLocationDegrees],
               let latitude = regionData["latitude"],
               let longitude = regionData["longitude"],
               let latitudeDelta = regionData["latitudeDelta"],
               let longitudeDelta = regionData["longitudeDelta"] {
                
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                return MKCoordinateRegion(center: center, span: span)
            }
        } catch {
            print("Error al deserializar la región")
        }
        
        return nil
    }

}
