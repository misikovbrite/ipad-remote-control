import Foundation

// Roku External Control Protocol (ECP) via HTTP on port 8060
class RokuProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private(set) var isConnected = false

    private let keyMap: [RemoteKey: String] = [
        .up: "Up",
        .down: "Down",
        .left: "Left",
        .right: "Right",
        .enter: "Select",
        .back: "Back",
        .home: "Home",
        .power: "Power",
        .volumeUp: "VolumeUp",
        .volumeDown: "VolumeDown",
        .mute: "VolumeMute",
        .channelUp: "ChannelUp",
        .channelDown: "ChannelDown",
        .play: "Play",
        .rewind: "Rev",
        .fastForward: "Fwd",
        .num0: "Lit_0",
        .num1: "Lit_1",
        .num2: "Lit_2",
        .num3: "Lit_3",
        .num4: "Lit_4",
        .num5: "Lit_5",
        .num6: "Lit_6",
        .num7: "Lit_7",
        .num8: "Lit_8",
        .num9: "Lit_9",
        .netflix: "Netflix",
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
    }

    func connect() async throws {
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/query/device-info")!
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TVProtocolError.connectionFailed("Roku not reachable")
        }
        isConnected = true
    }

    func disconnect() {
        isConnected = false
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let rokuKey = keyMap[key] else { throw TVProtocolError.unsupportedCommand }
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/keypress/\(rokuKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        for char in text {
            let encoded = String(char).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let url = URL(string: "http://\(device.ipAddress):\(device.port)/keypress/Lit_\(encoded)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let (_, _) = try await URLSession.shared.data(for: request)
        }
    }

    func sendMouseMove(dx: Float, dy: Float) async throws {
        throw TVProtocolError.unsupportedCommand
    }

    func sendMouseClick() async throws {
        try await sendKey(.enter)
    }

    func sendMouseScroll(delta: Float) async throws {
        throw TVProtocolError.unsupportedCommand
    }

    func getApps() async throws -> [TVApp] {
        guard isConnected else { throw TVProtocolError.notConnected }
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/query/apps")!
        let (data, _) = try await URLSession.shared.data(from: url)
        // Parse XML response
        let xml = String(data: data, encoding: .utf8) ?? ""
        var apps: [TVApp] = []
        let pattern = #"id="([^"]+)"[^>]*>([^<]+)</app>"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(xml.startIndex..., in: xml)
        regex?.enumerateMatches(in: xml, range: range) { match, _, _ in
            guard let match else { return }
            if let idRange = Range(match.range(at: 1), in: xml),
               let nameRange = Range(match.range(at: 2), in: xml) {
                let id = String(xml[idRange])
                let name = String(xml[nameRange])
                let iconURL = URL(string: "http://\(self.device.ipAddress):\(self.device.port)/query/icon/\(id)")
                apps.append(TVApp(id: id, name: name, iconURL: iconURL))
            }
        }
        return apps
    }

    func launchApp(_ app: TVApp) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/launch/\(app.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
