import Foundation

// Philips Ambilight TV via JointSpace API (HTTP port 1925)
class PhilipsProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private(set) var isConnected = false

    private let keyMap: [RemoteKey: String] = [
        .up: "CursorUp",
        .down: "CursorDown",
        .left: "CursorLeft",
        .right: "CursorRight",
        .enter: "Confirm",
        .back: "Back",
        .home: "Home",
        .power: "Standby",
        .volumeUp: "VolumeUp",
        .volumeDown: "VolumeDown",
        .mute: "Mute",
        .channelUp: "ChannelStepUp",
        .channelDown: "ChannelStepDown",
        .play: "Play",
        .pause: "Pause",
        .stop: "Stop",
        .rewind: "Rewind",
        .fastForward: "FastForward",
        .num0: "Digit0",
        .num1: "Digit1",
        .num2: "Digit2",
        .num3: "Digit3",
        .num4: "Digit4",
        .num5: "Digit5",
        .num6: "Digit6",
        .num7: "Digit7",
        .num8: "Digit8",
        .num9: "Digit9",
        .source: "Source",
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
    }

    func connect() async throws {
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/6/system")!
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TVProtocolError.connectionFailed("Philips TV not reachable")
        }
        isConnected = true
    }

    func disconnect() {
        isConnected = false
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let philipsKey = keyMap[key] else { throw TVProtocolError.unsupportedCommand }
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/6/input/key")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["key": philipsKey]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        // Philips: send each character as key
        for char in text {
            let url = URL(string: "http://\(device.ipAddress):\(device.port)/6/input/key")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["key": "Digit\(char)"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: request)
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
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/6/applications")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let applications = json["applications"] as? [[String: Any]] else { return [] }
        return applications.compactMap { app in
            guard let id = app["id"] as? String, let label = app["label"] as? String else { return nil }
            return TVApp(id: id, name: label, iconURL: nil)
        }
    }

    func launchApp(_ app: TVApp) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let url = URL(string: "http://\(device.ipAddress):\(device.port)/6/applications/\(app.id)/launch")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
