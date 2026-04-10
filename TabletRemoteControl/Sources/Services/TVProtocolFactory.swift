import Foundation

class TVProtocolFactory {
    static func make(for device: TVDevice) -> any TVProtocol {
        switch device.brand {
        case .samsung:
            return SamsungProtocol(device: device)
        case .lg:
            return LGProtocol(device: device)
        case .sony:
            return SonyProtocol(device: device)
        case .roku:
            return RokuProtocol(device: device)
        case .androidTV, .fireTV:
            return ADBProtocol(device: device)
        case .philips:
            return PhilipsProtocol(device: device)
        case .appleTV, .unknown:
            // Fallback: basic ADB or no-op
            return ADBProtocol(device: device)
        }
    }
}
