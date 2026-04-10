import Foundation
import Combine

protocol TVProtocol: AnyObject {
    var device: TVDevice { get }
    var isConnected: Bool { get }

    func connect() async throws
    func disconnect()
    func sendKey(_ key: RemoteKey) async throws
    func sendText(_ text: String) async throws
    func sendMouseMove(dx: Float, dy: Float) async throws
    func sendMouseClick() async throws
    func sendMouseScroll(delta: Float) async throws
    func getApps() async throws -> [TVApp]
    func launchApp(_ app: TVApp) async throws
}

struct TVApp: Identifiable {
    let id: String
    let name: String
    let iconURL: URL?
}

enum TVProtocolError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case commandFailed(String)
    case unsupportedCommand
    case timeout

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to TV"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .unsupportedCommand: return "This command is not supported"
        case .timeout: return "Connection timed out"
        }
    }
}
