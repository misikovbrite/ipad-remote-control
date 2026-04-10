import Foundation

// Sony Bravia TV via IRCC (IP Remote Control Command) + REST API
class SonyProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private(set) var isConnected = false
    private var authCookie: String?

    private let keyMap: [RemoteKey: String] = [
        .up: "AAAAAQAAAAEAAAAbAA==",
        .down: "AAAAAQAAAAEAAAAcAA==",
        .left: "AAAAAQAAAAEAAAAdAA==",
        .right: "AAAAAQAAAAEAAAAeAA==",
        .enter: "AAAAAQAAAAEAAAAlAA==",
        .back: "AAAAAgAAAJcAAAAjAA==",
        .home: "AAAAAQAAAAEAAABgAA==",
        .power: "AAAAAQAAAAEAAAAVAw==",
        .volumeUp: "AAAAAQAAAAEAAAASAw==",
        .volumeDown: "AAAAAQAAAAEAAAATAw==",
        .mute: "AAAAAQAAAAEAAAAUAw==",
        .channelUp: "AAAAAQAAAAEAAAAQAw==",
        .channelDown: "AAAAAQAAAAEAAAARAw==",
        .play: "AAAAAgAAAJcAAAAaAA==",
        .pause: "AAAAAgAAAJcAAAAZAA==",
        .stop: "AAAAAgAAAJcAAAAYAA==",
        .rewind: "AAAAAgAAAJcAAAAbAA==",
        .fastForward: "AAAAAgAAAJcAAAAcAA==",
        .num0: "AAAAAQAAAAEAAAAJAw==",
        .num1: "AAAAAQAAAAEAAAAuAw==",
        .num2: "AAAAAQAAAAEAAAAvAw==",
        .num3: "AAAAAQAAAAEAAAAkAw==",
        .num4: "AAAAAQAAAAEAAAAlAw==",
        .num5: "AAAAAQAAAAEAAAAmAw==",
        .num6: "AAAAAQAAAAEAAAAnAw==",
        .num7: "AAAAAQAAAAEAAAAoAw==",
        .num8: "AAAAAQAAAAEAAAApAw==",
        .num9: "AAAAAQAAAAEAAAAqAw==",
        .netflix: "AAAAAgAAABoAAAB8Aw==",
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
    }

    func connect() async throws {
        // Sony uses HTTP - just verify the TV is reachable
        let url = URL(string: "http://\(device.ipAddress)/sony/system")!
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["method": "getSystemInformation", "id": 33, "params": [], "version": "1.0"] as [String: Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TVProtocolError.connectionFailed("TV not reachable")
        }
        isConnected = true
    }

    func disconnect() {
        isConnected = false
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let irCode = keyMap[key] else { throw TVProtocolError.unsupportedCommand }

        let url = URL(string: "http://\(device.ipAddress)/sony/IRCC")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"", forHTTPHeaderField: "SOAPAction")

        let soapBody = """
        <?xml version="1.0"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <s:Body>
            <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
              <IRCCCode>\(irCode)</IRCCCode>
            </u:X_SendIRCC>
          </s:Body>
        </s:Envelope>
        """
        request.httpBody = soapBody.data(using: .utf8)
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let url = URL(string: "http://\(device.ipAddress)/sony/system")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "method": "setTextForm",
            "id": 1,
            "params": [["text": text]],
            "version": "1.0"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, _) = try await URLSession.shared.data(for: request)
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
        let url = URL(string: "http://\(device.ipAddress)/sony/appControl")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["method": "getApplicationList", "id": 60, "params": [], "version": "1.0"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["result"] as? [[Any]],
              let apps = results.first as? [[String: Any]] else { return [] }
        return apps.compactMap { app in
            guard let uri = app["uri"] as? String, let title = app["title"] as? String else { return nil }
            return TVApp(id: uri, name: title, iconURL: nil)
        }
    }

    func launchApp(_ app: TVApp) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let url = URL(string: "http://\(device.ipAddress)/sony/appControl")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["method": "setActiveApp", "id": 601, "params": [["uri": app.id]], "version": "1.0"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
