import Foundation

enum TVBrand: String, Codable, CaseIterable {
    case samsung = "Samsung"
    case lg = "LG"
    case sony = "Sony"
    case roku = "Roku"
    case appleTV = "Apple TV"
    case androidTV = "Android TV"
    case philips = "Philips"
    case fireTV = "Fire TV"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .samsung: return "tv"
        case .lg: return "tv"
        case .sony: return "tv"
        case .roku: return "tv.and.mediabox"
        case .appleTV: return "appletv"
        case .androidTV: return "tv"
        case .philips: return "tv"
        case .fireTV: return "flame"
        case .unknown: return "tv"
        }
    }

    var defaultPort: Int {
        switch self {
        case .samsung: return 8001
        case .lg: return 3000
        case .sony: return 80
        case .roku: return 8060
        case .appleTV: return 7000
        case .androidTV, .fireTV: return 5555
        case .philips: return 1925
        case .unknown: return 8001
        }
    }
}

enum TVConnectionState {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

struct TVDevice: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let brand: TVBrand
    let ipAddress: String
    let port: Int
    var modelName: String?
    var connectionState: TVConnectionState = .disconnected

    // connectionState is transient — excluded from persistence
    enum CodingKeys: String, CodingKey {
        case id, name, brand, ipAddress, port, modelName
    }

    static func == (lhs: TVDevice, rhs: TVDevice) -> Bool {
        lhs.id == rhs.id
    }
}
