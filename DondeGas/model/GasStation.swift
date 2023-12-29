import Foundation

// Association between fuel types and the name each one has in the API response.
enum FuelType: String, Codable, CaseIterable, Identifiable {
    case diesel = "Precio Gasoleo A"
    case dieselP = "Precio Gasoleo Premium"
    case sp95 = "Precio Gasolina 95 E5"
    case sp95P = "Precio Gasolina 95 E5 Premium"
    case sp98 = "Precio Gasolina 98 E5"
    case glp = "Precio Gases licuados del petróleo"
    case hidrogen = "Precio Hidrogeno"
    var id: Self { return self }
}

// Structure in which the API response content is decoded into.
struct GasStationsResponse: Decodable {
    let Fecha: String
    let ListaEESSPrecio: [GasStation]
}

struct GasStation: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let cp: String
    let address: String
    let schedule: String
    let latitude: String
    let longitude: String
    let municipality: String
    let province: String
    var prices: [FuelType:String?]

    private enum CodingKeys: String, CodingKey {
        case id = "IDEESS"
        case name = "Rótulo"
        case cp = "C.P."
        case address = "Dirección"
        case schedule = "Horario"
        case latitude = "Latitud"
        case longitude = "Longitud (WGS84)"
        case municipality = "Municipio"
        case province = "Provincia"
        
        case sp95 = "Precio Gasolina 95 E5"
        case sp95P = "Precio Gasolina 95 E5 Premium"
        case sp98 = "Precio Gasolina 98 E5"
        case diesel = "Precio Gasoleo A"
        case dieselP = "Precio Gasoleo Premium"
        case glp = "Precio Gases licuados del petróleo"
        case hidrogen = "Precio Hidrogeno"
        case dynamicKey
        
        init?(stringValue: String) {
                    if stringValue.starts(with: "Precio ") {
                        switch stringValue {
                            case "Precio Gasolina 95 E5": self = .sp95
                            case "Precio Gasolina 95 E5 Premium": self = .sp95P
                            case "Precio Gasolina 98 E5": self = .sp98
                            case "Precio Gasoleo A": self = .diesel
                            case "Precio Gasoleo Premium": self = .dieselP
                            case "Precio Gases licuados del petróleo": self = .glp
                            case "Precio Hidrogeno": self = .hidrogen
                            default: self = .dynamicKey
                        }
                        
                    } else {
                        return nil
                    }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        cp = try container.decode(String.self, forKey: .cp)
        address = try container.decode(String.self, forKey: .address)
        schedule = try container.decode(String.self, forKey: .schedule)
        latitude = try container.decode(String.self, forKey: .latitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        municipality = try container.decode(String.self, forKey: .municipality)
        province = try container.decode(String.self, forKey: .province)

        prices = [:]
        for fuelType in FuelType.allCases {
            let key = CodingKeys(stringValue: fuelType.rawValue) ?? .dynamicKey
                    if let priceString = try container.decodeIfPresent(String.self, forKey: key) {
                       prices[fuelType] = priceString.replacingOccurrences(of: ",", with: ".")
                    } else {
                       prices[fuelType] = "0.000"
                    }
        }
    }
}
