//
//  DondeGasViewModel.swift
//  DondeGas
//
//  Created by Sergio Frejo on 17/11/23.
//

import Foundation
import _MapKit_SwiftUI
import SwiftUI
import Combine

class DondeGasViewModel: ObservableObject {
    
    private var locationManager = LocationManager.shared
    let palette = ColorPalette()
    
    struct GasStationLocation: Identifiable {
        let location: CLLocationCoordinate2D
        let name: String
        let id: String
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var isFuelMenuVisible: Bool = false
    @Published var isLocationMenuVisible: Bool = false
    
    @Published var collectionDate: String = ""
    @Published var allGasStations: [GasStation] = []
    @Published var gasStations: [GasStation] = []
    @Published var gasStationLocations: [GasStationLocation] = []
    @Published var selectedFuelType: FuelType = .sp95
    @Published var expandedItem: GasStation.ID = ""
    
    @Published var mapTarget: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @Published var usingCustomLocation: Bool = false
    @Published var reachLimit: Int = 5
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var locationSearchQuery: String = ""
    private var locationSearchService = LocationSearchService()
    private var searchCancellable: AnyCancellable?
    
    public let CARD_HEIGHT_COLLAPSED = CGFloat(425)
    public let CARD_HEIGHT_NEUTRAL = CGFloat(180)
    public let CARD_HEIGHT_EXPANDED = CGFloat(-75)
    private var CARDSTATE_LOWER_THRESHOLD: CGFloat { CARD_HEIGHT_NEUTRAL * 1.20 }
    private var CARDSTATE_UPPER_THRESHOLD: CGFloat { CARD_HEIGHT_EXPANDED * 0.8 }
    
    enum CardState {
        case COLLAPSED
        case NEUTRAL
        case EXPANDED
    }
    @Published var latestCardState: CardState = .NEUTRAL
    @Published var slidingCardOffset = CGSize.zero
    
    init() {
        loadGasStations()
        
        slidingCardOffset = CGSize(width: CGFloat.zero, height: Double(CARD_HEIGHT_NEUTRAL)) // Iniciar en 180
        
        locationSearchService.onUpdate = { [weak self] results in
                    self?.searchResults = results
                }

                searchCancellable = $locationSearchQuery
                    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                    .sink { [weak self] query in
                        self?.locationSearchService.updateSearch(text: query)
                    }
    }
    
    func loadGasStations() {
        isLoading = true
        let url = URL(string: "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/")!

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(GasStationsResponse.self, from: data)
                        self?.allGasStations = Array(decodedResponse.ListaEESSPrecio)
                        
                        // Collection date management
                        let dateElements = String(decodedResponse.Fecha).split(separator: " ")
                        self?.collectionDate = String(dateElements.first ?? "")


                        self?.filterGasStations()
                    } catch {
                        print("Decoding error: \(error)")
                        self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    }
                } else if let error = error {
                    print("Network error: \(error)")
                    self?.errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }
        }.resume()
        
    }
    
    func filterGasStations() {
        // Location filtering
        gasStations = []
        gasStations = allGasStations.filter { locationManager.distanceToGasStation(station: $0) < Double(reachLimit) }
        
        // Fuel type filtering
        gasStations = gasStations.filter { $0.prices[selectedFuelType] != nil && $0.prices[selectedFuelType] != "" }
        
        // Price sorting
        gasStations.sort { Double(($0.prices[selectedFuelType] ?? "") ?? "") ?? Double.infinity < Double(($1.prices[selectedFuelType] ?? "") ?? "") ?? Double.infinity }
        
        // Showing the results in the map
        self.loadStationsLocations()
    }
    
    func loadStationsLocations() {
        
        gasStationLocations.removeAll()
        
        for gasStation in gasStations {
            if let lat = Double(gasStation.latitude.replacingOccurrences(of: ",", with: ".")), let long = Double(gasStation.longitude.replacingOccurrences(of: ",", with: ".")) {
                gasStationLocations.append(
                    GasStationLocation(
                        location: CLLocationCoordinate2D(latitude: lat, longitude: long),
                        name: gasStation.name,
                        id: gasStation.id
                    )
                )
            }
                    }
    }
    
    func hideMenus() {
        isFuelMenuVisible = false
        isLocationMenuVisible = false
    }
    
    func hideFilters() {
        isFuelMenuVisible = false
        isLocationMenuVisible = false
    }
    
    func setCardState(height: CardState) {
        switch height {
        case .COLLAPSED:
            latestCardState = .COLLAPSED
            slidingCardOffset.height = CARD_HEIGHT_COLLAPSED
        case .NEUTRAL:
            latestCardState = .NEUTRAL
            slidingCardOffset.height = CARD_HEIGHT_NEUTRAL
        case .EXPANDED:
            latestCardState = .EXPANDED
            slidingCardOffset.height = CARD_HEIGHT_EXPANDED
        }
    }
    
    func setCardState(movement: CGSize) {
        switch movement.height {
        case _ where movement.height < CARDSTATE_UPPER_THRESHOLD:
            setCardState(height: .EXPANDED)
        case _ where movement.height > CARDSTATE_LOWER_THRESHOLD:
            setCardState(height: .COLLAPSED)
        default:
            setCardState(height: .NEUTRAL)
        }
    }
    
    func fuelTypeToCommercialName(fuelType: FuelType) -> String {
        switch fuelType {
        case .diesel:
            return "Diésel"
        case .dieselP:
            return "Diésel Premium"
        case .sp95:
            return "Gasolina 95"
        case .sp95P:
            return "Gasolina 95 Premium"
        case .sp98:
            return "Gasolina 98"
        case .glp:
            return "Gas licuado"
        case .hidrogen:
            return "Hidrógeno"
        }
    }
    
    func weekdayFromLetter(dayLetter: String) -> String {
        switch dayLetter {
            case "L":
                return "Lunes"
            case "M":
                return "Martes"
            case "X":
                return "Miércoles"
            case "J":
                return "Jueves"
            case "V":
                return "Viernes"
            case "S":
                return "Sábado"
            case "D":
                return "Domingo"
            case "":
                return ""
            default:
                return "Día no válido"
        }
    }
    
    func getFuelTypeColor(fuelType: FuelType) -> Color {
        switch fuelType {
        case .sp95:
            return palette.mango
        case .sp95P:
            return palette.tangerine
        case .sp98:
            return palette.sunburst
        case .diesel:
            return palette.sand
        case .dieselP:
            return palette.hotSand
        case .glp:
            return palette.softGreen
        case .hidrogen:
            return palette.greenishBlue
        }
    }
    
    func getColorCode(gasStation gasStID: GasStation.ID) -> Color {
        if gasStations.count < 4 {
            if let gasSt = gasStations.first(where: {$0.id == gasStID}), let stationIdx = gasStations.firstIndex(of: gasSt) {
                switch stationIdx {
                case 0:
                    return .green
                case 1:
                    return .orange
                case 2:
                    return .red
                default:
                    return .white
                }
                
            } else {
                return .white
            }
        } else {
            if gasStations.prefix(Int(Double(gasStations.count) * 0.25)).contains(where: { $0.id == gasStID }) {
                return Color.green
            } else if gasStations.prefix(Int(Double(gasStations.count) * 0.75)).contains(where: { $0.id == gasStID }) {
                return Color.orange
            } else {
                return Color.red
            }
        }
    }
    
    func getOpenStatus(scheduleString: String) -> String {
        let diaANumero = [
            "L":1,
            "M":2,
            "X":3,
            "J":4,
            "V":5,
            "S":6,
            "D":7,
        ]
        
        struct Schedule {
            var weekdays: ClosedRange<Int>
            var scheds: [ClosedRange<Int>]
        }
        
        var weeklySchedule: [Schedule] = []
        
        for stretch in scheduleString.split(separator: ";") { // Loop among different open times
            
            var sched: Schedule = Schedule(weekdays: 0...0, scheds: [])
            
            let statusItems = stretch.split(separator: " ")
            
            // Weekdays interval
            let weekdayLimits = statusItems[0].split(separator: "-")
            if weekdayLimits.count > 1 {
                if let lower = diaANumero[String(weekdayLimits[0])], let upper = diaANumero[String(weekdayLimits[1]).replacingOccurrences(of: ":", with: "")] {
                    sched.weekdays = lower...upper
                }
            } else {
                if let limit = diaANumero[String(weekdayLimits[0]).replacingOccurrences(of: ":", with: "")] {
                    sched.weekdays = limit...limit
                }
            }

            // Open hours interval
            let hourTimes = statusItems[1].split(separator: "-")
            if hourTimes[0] == "24H" {
                sched.scheds.append(0...(24*60))
            } else {
                let openTime = String(hourTimes[0])
                let closeTime = String(hourTimes[1])
                
                let openTimeParts = openTime.split(separator: ":")
                var openTimeInMinutes = 0
                if let openTimeHours = Int(openTimeParts[0]), let openTimeMinutes = Int(openTimeParts[1]) {
                   openTimeInMinutes = openTimeMinutes + 60 * openTimeHours
                }
                
                let closeTimeParts = closeTime.split(separator: ":")
                var closeTimeInMinutes = 0
                if let closeTimeHours = Int(closeTimeParts[0]) == 0 ? 24:Int(closeTimeParts[0]),
                    let closeTimeMinutes = Int(closeTimeParts[1]) {
                   closeTimeInMinutes = closeTimeMinutes + (60 * closeTimeHours)
                }

                if openTimeInMinutes < closeTimeInMinutes {
                    sched.scheds.append(openTimeInMinutes...closeTimeInMinutes)
                }
                
            }
            
            weeklySchedule.append(sched)
        }
        
        let today = Int(Date().formatted(Date.FormatStyle().weekday(.oneDigit))) ?? 0
        var currentTimeInMinutes: Int {
            let hours = Calendar.current.component(.hour, from: Date())
            let minutes = (hours * 60) + Calendar.current.component(.minute, from: Date())
            
            return minutes
        }

        // Obtaining the current hour time. I mean, only the hour. Like, 7 out of 07:45.
        var currentHour: Int {
            return Calendar.current.component(.hour, from: Date())
        }
        
        for period in weeklySchedule {
            if period.weekdays.contains(today) {
                for sched in period.scheds {
                    if sched.contains(currentTimeInMinutes) {
                        if sched.lowerBound == 0 && sched.upperBound == 24*60 {
                            return "Abierto 24H"
                        } else {
                            return "Abierto hasta \n las \(String(sched.upperBound / 60)):\(String(sched.upperBound % 60))0"
                        }
                    }
                }
            }
        }
        
        return "Cerrado"
    }
    
    func getSchedule(scheduleString: String) -> String {
        var fullSchedule = ""

        for stretch in scheduleString.split(separator: ";") { // Loop between open periods
            
            let statusItems = stretch.split(separator: " ")
            var stretchSchedule = ""
            // Weekday interval
            let weekdayLimits = statusItems[0].split(separator: "-")
            var from = ""
            var to = ""
            if weekdayLimits.count > 1 {
                from = String(weekdayLimits[0])
                to = String(weekdayLimits[1]).replacingOccurrences(of: ":", with: "")
            } else {
                to = String(weekdayLimits[0]).replacingOccurrences(of: ":", with: "")
                
            }
            
            // Open time interval
            let hourTimes = statusItems[1].split(separator: "-")
            if hourTimes[0] == "24H" {
                stretchSchedule = "\(weekdayFromLetter(dayLetter: from)) \(from != "" ? "a" : "" ) \(weekdayFromLetter(dayLetter: to)):\n 24H\n"
            } else {
                let openingTime = String(hourTimes[0])
                let closingTime = String(hourTimes[1])
                
                stretchSchedule = "\(weekdayFromLetter(dayLetter: from)) \(from != "" ? "a" : "" ) \(weekdayFromLetter(dayLetter: to)):\n \(openingTime) - \(closingTime)\n"
            }
        
            fullSchedule += stretchSchedule
        }
        
        return fullSchedule.isEmpty ? "Horario no disponible" : fullSchedule
    }

}
