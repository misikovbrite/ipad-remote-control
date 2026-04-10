import Foundation

// LG WebOS TV via WebSocket (port 3000), ssap:// protocol
class LGProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private(set) var isConnected = false
    private var clientKey: String?
    private var commandCallbacks: [String: CheckedContinuation<[String: Any], Error>] = [:]
    private var messageIdCounter = 1

    private let keyMap: [RemoteKey: String] = [
        .up: "UP",
        .down: "DOWN",
        .left: "LEFT",
        .right: "RIGHT",
        .enter: "ENTER",
        .back: "BACK",
        .home: "HOME",
        .menu: "MENU",
        .power: "POWER",
        .volumeUp: "VOLUMEUP",
        .volumeDown: "VOLUMEDOWN",
        .mute: "MUTE",
        .channelUp: "CHANNELUP",
        .channelDown: "CHANNELDOWN",
        .play: "PLAY",
        .pause: "PAUSE",
        .stop: "STOP",
        .rewind: "REWIND",
        .fastForward: "FASTFORWARD",
        .num0: "0",
        .num1: "1",
        .num2: "2",
        .num3: "3",
        .num4: "4",
        .num5: "5",
        .num6: "6",
        .num7: "7",
        .num8: "8",
        .num9: "9",
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        // Load saved client key
        self.clientKey = UserDefaults.standard.string(forKey: "lg_key_\(device.ipAddress)")
    }

    func connect() async throws {
        let urlString = "ws://\(device.ipAddress):\(device.port)"
        guard let url = URL(string: urlString) else {
            throw TVProtocolError.connectionFailed("Invalid URL")
        }
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        // Send registration request
        let regPayload = buildRegistrationPayload()
        try await send(json: regPayload)

        // Wait for registration response
        let response = try await withTimeout(seconds: 10) { [weak self] in
            try await self?.webSocketTask?.receive()
        }

        if case .string(let str) = response,
           let data = str.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let payload = json["payload"] as? [String: Any],
           let key = payload["client-key"] as? String {
            clientKey = key
            UserDefaults.standard.set(key, forKey: "lg_key_\(device.ipAddress)")
        }

        isConnected = true
        startReceiving()
    }

    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let lgKey = keyMap[key] else { throw TVProtocolError.unsupportedCommand }
        _ = try await sendCommand(uri: "ssap://com.webos.service.ime/sendKeycode", payload: ["keyCode": lgKey])
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        _ = try await sendCommand(uri: "ssap://com.webos.service.ime/insertText",
                                  payload: ["text": text, "replace": 0])
    }

    func sendMouseMove(dx: Float, dy: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "type": "move",
            "dx": dx,
            "dy": dy,
            "drag": 0
        ]
        let msg: [String: Any] = ["type": "input", "payload": payload]
        try await send(json: msg)
    }

    func sendMouseClick() async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let msg: [String: Any] = ["type": "input", "payload": ["type": "click"]]
        try await send(json: msg)
    }

    func sendMouseScroll(delta: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = ["type": "scroll", "dx": 0, "dy": delta, "drag": 0]
        let msg: [String: Any] = ["type": "input", "payload": payload]
        try await send(json: msg)
    }

    func getApps() async throws -> [TVApp] {
        let response = try await sendCommand(uri: "ssap://com.webos.applicationManager/listApps")
        guard let apps = response["apps"] as? [[String: Any]] else { return [] }
        return apps.compactMap { app in
            guard let id = app["id"] as? String, let title = app["title"] as? String else { return nil }
            let iconURL = (app["icon"] as? String).flatMap { URL(string: $0) }
            return TVApp(id: id, name: title, iconURL: iconURL)
        }
    }

    func launchApp(_ app: TVApp) async throws {
        _ = try await sendCommand(uri: "ssap://system.launcher/launch", payload: ["id": app.id])
    }

    // MARK: - Private

    @discardableResult
    private func sendCommand(uri: String, payload: [String: Any] = [:]) async throws -> [String: Any] {
        let id = "\(messageIdCounter)"
        messageIdCounter += 1

        let msg: [String: Any] = [
            "type": "request",
            "id": id,
            "uri": uri,
            "payload": payload
        ]
        try await send(json: msg)

        return try await withCheckedThrowingContinuation { continuation in
            commandCallbacks[id] = continuation
        }
    }

    private func buildRegistrationPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "forcePairing": false,
            "pairingType": "PROMPT",
            "manifest": [
                "manifestVersion": 1,
                "appVersion": "1.0",
                "signed": [
                    "created": "20201020",
                    "appId": "com.britetodo.tabletremote",
                    "vendorId": "com.britetodo",
                    "localizedAppNames": ["": "Tablet Remote"],
                    "localizedVendorNames": ["": "Brite Technologies"],
                    "permissions": ["LAUNCH", "LAUNCH_WEBAPP", "APP_TO_APP", "CONTROL_AUDIO", "CONTROL_INPUT_TEXT", "CONTROL_MOUSE_AND_KEYBOARD", "READ_INSTALLED_APPS", "READ_LGE_SDX", "READ_NOTIFICATIONS", "SEARCH", "WRITE_SETTINGS", "WRITE_NOTIFICATION_ALERT", "CONTROL_POWER", "READ_CURRENT_CHANNEL", "READ_RUNNING_APPS", "READ_UPDATE_INFO", "UPDATE_FROM_REMOTE_APP", "READ_LGE_TV_INPUT_EVENTS", "READ_TV_CURRENT_TIME"]
                ],
                "permissions": ["LAUNCH", "LAUNCH_WEBAPP", "APP_TO_APP", "CLOSE", "TEST_OPEN", "TEST_PROTECTED", "CONTROL_AUDIO", "CONTROL_DISPLAY", "CONTROL_INPUT_JOYSTICK", "CONTROL_INPUT_MEDIA_RECORDING", "CONTROL_INPUT_MEDIA_PLAYBACK", "CONTROL_INPUT_TV", "CONTROL_POWER", "READ_APP_STATUS", "READ_CURRENT_CHANNEL", "READ_INPUT_DEVICE_LIST", "READ_NETWORK_STATE", "READ_RUNNING_APPS", "READ_TV_CHANNEL_LIST", "WRITE_NOTIFICATION_TOAST", "READ_POWER_STATE", "READ_COUNTRY_INFO"],
                "signatures": [["signatureVersion": 1, "signature": "eyJhbGdvcml0aG0iOiJSU0EtU0hBMjU2IiwiY2VydGlmaWNhdGVWZXJzaW9uIjoiMSJ9"]]
            ]
        ]
        if let key = clientKey {
            payload["client-key"] = key
        }
        return ["type": "register", "id": "register_0", "payload": payload]
    }

    private func send(json: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        try await webSocketTask?.send(.string(String(data: data, encoding: .utf8)!))
    }

    private func startReceiving() {
        Task { [weak self] in
            guard let self else { return }
            while self.isConnected {
                do {
                    let msg = try await self.webSocketTask?.receive()
                    if case .string(let str) = msg,
                       let data = str.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let id = json["id"] as? String,
                       let payload = json["payload"] as? [String: Any] {
                        self.commandCallbacks[id]?.resume(returning: payload)
                        self.commandCallbacks.removeValue(forKey: id)
                    }
                } catch {
                    self.isConnected = false
                    break
                }
            }
        }
    }
}

extension LGProtocol: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) { isConnected = true }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) { isConnected = false }
}
