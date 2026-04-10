import Foundation
import Combine

@MainActor
class TVConnectionManager: ObservableObject {
    @Published var currentProtocol: (any TVProtocol)?
    @Published var connectionState: TVConnectionState = .disconnected
    @Published var connectedDevice: TVDevice?

    func connect(to device: TVDevice) async {
        connectionState = .connecting
        let proto = TVProtocolFactory.make(for: device)
        do {
            try await proto.connect()
            currentProtocol = proto
            connectedDevice = device
            connectionState = .connected
        } catch {
            connectionState = .failed(error.localizedDescription)
        }
    }

    func disconnect() {
        currentProtocol?.disconnect()
        currentProtocol = nil
        connectedDevice = nil
        connectionState = .disconnected
    }

    func sendKey(_ key: RemoteKey) {
        guard let proto = currentProtocol else { return }
        Task { try? await proto.sendKey(key) }
    }

    func sendText(_ text: String) {
        guard let proto = currentProtocol else { return }
        Task { try? await proto.sendText(text) }
    }

    func sendMouseMove(dx: Float, dy: Float) {
        guard let proto = currentProtocol else { return }
        Task { try? await proto.sendMouseMove(dx: dx, dy: dy) }
    }

    func sendMouseClick() {
        guard let proto = currentProtocol else { return }
        Task { try? await proto.sendMouseClick() }
    }

    func sendMouseScroll(delta: Float) {
        guard let proto = currentProtocol else { return }
        Task { try? await proto.sendMouseScroll(delta: delta) }
    }
}
