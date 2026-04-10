import Foundation
import Network

// Samsung Smart TV Remote API via WebSocket (port 8001/8002)
class SamsungProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private(set) var isConnected = false

    // Samsung key name mapping
    private let keyMap: [RemoteKey: String] = [
        .up: "KEY_UP",
        .down: "KEY_DOWN",
        .left: "KEY_LEFT",
        .right: "KEY_RIGHT",
        .enter: "KEY_ENTER",
        .back: "KEY_RETURN",
        .home: "KEY_HOME",
        .menu: "KEY_MENU",
        .power: "KEY_POWER",
        .powerOn: "KEY_POWER",
        .powerOff: "KEY_POWER",
        .volumeUp: "KEY_VOLUP",
        .volumeDown: "KEY_VOLDOWN",
        .mute: "KEY_MUTE",
        .channelUp: "KEY_CHUP",
        .channelDown: "KEY_CHDOWN",
        .play: "KEY_PLAY",
        .pause: "KEY_PAUSE",
        .stop: "KEY_STOP",
        .rewind: "KEY_REWIND",
        .fastForward: "KEY_FF",
        .source: "KEY_SOURCE",
        .netflix: "KEY_NETFLIX",
        .youtube: "KEY_YOUTUBE",
        .num0: "KEY_0",
        .num1: "KEY_1",
        .num2: "KEY_2",
        .num3: "KEY_3",
        .num4: "KEY_4",
        .num5: "KEY_5",
        .num6: "KEY_6",
        .num7: "KEY_7",
        .num8: "KEY_8",
        .num9: "KEY_9",
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect() async throws {
        let appName = "Tablet Remote".data(using: .utf8)!.base64EncodedString()
        let urlString = "ws://\(device.ipAddress):\(device.port)/api/v2/channels/samsung.remote.control?name=\(appName)"
        guard let url = URL(string: urlString) else {
            throw TVProtocolError.connectionFailed("Invalid URL")
        }
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        // Wait for connection acknowledgement
        let _ = try await withTimeout(seconds: 5) { [weak self] in
            try await self?.webSocketTask?.receive()
        }
        isConnected = true
        startReceiving()
    }

    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let samsungKey = keyMap[key] else { throw TVProtocolError.unsupportedCommand }

        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Click",
                "DataOfCmd": samsungKey,
                "Option": "false",
                "TypeOfRemote": "SendRemoteKey"
            ]
        ]
        try await send(json: payload)
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let encoded = text.data(using: .utf8)!.base64EncodedString()
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": encoded,
                "DataOfCmd": "base64",
                "TypeOfRemote": "SendInputString"
            ]
        ]
        try await send(json: payload)
    }

    func sendMouseMove(dx: Float, dy: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Move",
                "Position": ["x": dx, "y": dy, "Time": String(Int(Date().timeIntervalSince1970 * 1000))],
                "TypeOfRemote": "ProcessMouseDevice"
            ]
        ]
        try await send(json: payload)
    }

    func sendMouseClick() async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "LeftClick",
                "TypeOfRemote": "ProcessMouseDevice"
            ]
        ]
        try await send(json: payload)
    }

    func sendMouseScroll(delta: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": delta > 0 ? "ScrollUp" : "ScrollDown",
                "TypeOfRemote": "ProcessMouseDevice"
            ]
        ]
        try await send(json: payload)
    }

    func getApps() async throws -> [TVApp] {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "method": "ms.channel.emit",
            "params": ["event": "ed.installedApp.get", "to": "host"]
        ]
        try await send(json: payload)
        // Response handled asynchronously via receive loop
        return []
    }

    func launchApp(_ app: TVApp) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let payload: [String: Any] = [
            "method": "ms.channel.emit",
            "params": [
                "event": "ed.apps.launch",
                "to": "host",
                "data": ["appId": app.id, "action_type": "DEEP_LINK"]
            ]
        ]
        try await send(json: payload)
    }

    // MARK: - Private

    private func send(json: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        let string = String(data: data, encoding: .utf8)!
        try await webSocketTask?.send(.string(string))
    }

    private func startReceiving() {
        Task { [weak self] in
            guard let self else { return }
            while self.isConnected {
                do {
                    let _ = try await self.webSocketTask?.receive()
                } catch {
                    self.isConnected = false
                    break
                }
            }
        }
    }
}

extension SamsungProtocol: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        isConnected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
}

// MARK: - Timeout helper
func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T?) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            if let result = try await operation() {
                return result
            }
            throw TVProtocolError.timeout
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TVProtocolError.timeout
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
