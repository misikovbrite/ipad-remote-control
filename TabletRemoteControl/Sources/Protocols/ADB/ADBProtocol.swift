import Foundation
import Network

// Android TV / Fire TV via ADB over network (port 5555)
// ADB protocol: connect → auth → send shell commands
class ADBProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private(set) var isConnected = false
    private var connection: NWConnection?

    // Android key codes
    private let keyMap: [RemoteKey: Int] = [
        .up: 19,
        .down: 20,
        .left: 21,
        .right: 22,
        .enter: 23,
        .back: 4,
        .home: 3,
        .menu: 82,
        .power: 26,
        .volumeUp: 24,
        .volumeDown: 25,
        .mute: 91,
        .channelUp: 166,
        .channelDown: 167,
        .play: 126,
        .pause: 127,
        .stop: 86,
        .rewind: 89,
        .fastForward: 90,
        .num0: 7,
        .num1: 8,
        .num2: 9,
        .num3: 10,
        .num4: 11,
        .num5: 12,
        .num6: 13,
        .num7: 14,
        .num8: 15,
        .num9: 16,
        .netflix: 0, // launch via intent
        .youtube: 0,
    ]

    init(device: TVDevice) {
        self.device = device
        super.init()
    }

    func connect() async throws {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(device.ipAddress),
            port: NWEndpoint.Port(integerLiteral: UInt16(device.port))
        )
        connection = NWConnection(to: endpoint, using: .tcp)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isConnected = true
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: TVProtocolError.connectionFailed(error.localizedDescription))
                default:
                    break
                }
            }
            connection?.start(queue: .global())
        }

        // Send ADB CONNECT packet
        try await sendADBConnect()
    }

    func disconnect() {
        isConnected = false
        connection?.cancel()
        connection = nil
    }

    func sendKey(_ key: RemoteKey) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        guard let keyCode = keyMap[key], keyCode != 0 else {
            throw TVProtocolError.unsupportedCommand
        }
        try await sendShellCommand("input keyevent \(keyCode)")
    }

    func sendText(_ text: String) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let escaped = text.replacingOccurrences(of: " ", with: "%s")
        try await sendShellCommand("input text '\(escaped)'")
    }

    func sendMouseMove(dx: Float, dy: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        try await sendShellCommand("input mouse move \(Int(dx)) \(Int(dy))")
    }

    func sendMouseClick() async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        try await sendShellCommand("input mouse tap 0 0")
    }

    func sendMouseScroll(delta: Float) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        let direction = delta > 0 ? "2" : "3" // AXIS_VSCROLL
        try await sendShellCommand("input trackball roll \(direction) \(abs(Int(delta)))")
    }

    func getApps() async throws -> [TVApp] {
        guard isConnected else { throw TVProtocolError.notConnected }
        // Returns limited list of known streaming apps
        return [
            TVApp(id: "com.netflix.ninja", name: "Netflix", iconURL: nil),
            TVApp(id: "com.google.android.youtube.tv", name: "YouTube", iconURL: nil),
            TVApp(id: "com.amazon.avod.thirdpartyclient", name: "Prime Video", iconURL: nil),
            TVApp(id: "com.disney.disneyplus", name: "Disney+", iconURL: nil),
        ]
    }

    func launchApp(_ app: TVApp) async throws {
        guard isConnected else { throw TVProtocolError.notConnected }
        try await sendShellCommand("monkey -p \(app.id) -c android.intent.category.LAUNCHER 1")
    }

    // MARK: - Private ADB protocol

    private func sendADBConnect() async throws {
        // ADB CONNECT message: magic + version + maxdata + "host::features=..."
        var packet = Data()
        packet.append(contentsOf: [0x43, 0x4E, 0x58, 0x4E]) // CNXN magic
        packet.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // version 1
        packet.append(contentsOf: [0x00, 0x00, 0x10, 0x00]) // max data 4096
        let message = "host::features=shell_v2,cmd,stat_v2,ls_v2,fixed_push_mkdir\0"
        let msgData = message.data(using: .utf8)!
        let msgLen = UInt32(msgData.count).littleEndian
        withUnsafeBytes(of: msgLen) { packet.append(contentsOf: $0) }
        // checksum
        let checksum = msgData.reduce(UInt32(0)) { $0 + UInt32($1) }
        withUnsafeBytes(of: checksum.littleEndian) { packet.append(contentsOf: $0) }
        // magic
        let magic = (UInt32(0x43584E43) ^ 0xFFFFFFFF).littleEndian
        withUnsafeBytes(of: magic) { packet.append(contentsOf: $0) }
        packet.append(msgData)
        try await send(data: packet)
    }

    private func sendShellCommand(_ command: String) async throws {
        // For a real ADB implementation, shell commands require full ADB auth + open channel
        // This sends a simplified shell payload
        var packet = Data()
        packet.append(contentsOf: [0x4F, 0x50, 0x45, 0x4E]) // OPEN magic
        packet.append(contentsOf: [0x01, 0x00, 0x00, 0x00]) // local_id = 1
        packet.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // remote_id = 0
        let service = "shell:\(command)\0"
        let svcData = service.data(using: .utf8)!
        let msgLen = UInt32(svcData.count).littleEndian
        withUnsafeBytes(of: msgLen) { packet.append(contentsOf: $0) }
        let checksum = svcData.reduce(UInt32(0)) { $0 + UInt32($1) }
        withUnsafeBytes(of: checksum.littleEndian) { packet.append(contentsOf: $0) }
        let magic = (UInt32(0x4E45504F) ^ 0xFFFFFFFF).littleEndian
        withUnsafeBytes(of: magic) { packet.append(contentsOf: $0) }
        packet.append(svcData)
        try await send(data: packet)
    }

    private func send(data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection?.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: TVProtocolError.commandFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
