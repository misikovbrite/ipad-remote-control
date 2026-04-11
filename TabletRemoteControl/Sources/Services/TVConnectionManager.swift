import Foundation
import Combine

@MainActor
class TVConnectionManager: ObservableObject {
    @Published var currentProtocol: (any TVProtocol)?
    @Published var connectionState: TVConnectionState = .disconnected
    @Published var connectedDevice: TVDevice?
    @Published var savedDevices: [TVDevice] = []
    @Published var isReconnecting = false
    @Published var isDemoMode = false

    private let storeKey = "saved_tv_devices_v1"

    init() {
        loadSavedDevices()
        attemptReconnect()
    }

    // MARK: - Connect

    func connect(to device: TVDevice) async {
        connectionState = .connecting
        let proto = TVProtocolFactory.make(for: device)
        do {
            try await proto.connect()
            currentProtocol = proto
            connectedDevice = device
            connectionState = .connected
            isDemoMode = false
            saveDevice(device)
        } catch {
            connectionState = .failed(error.localizedDescription)
        }
    }

    func connectDemo() {
        let demo = TVDevice(
            id: "demo",
            name: "Demo TV",
            brand: .samsung,
            ipAddress: "192.168.1.100",
            port: 8001,
            modelName: "Demo Mode"
        )
        connectedDevice = demo
        currentProtocol = DemoProtocol(device: demo)
        connectionState = .connected
        isDemoMode = true
    }

    func disconnect() {
        currentProtocol?.disconnect()
        currentProtocol = nil
        connectedDevice = nil
        connectionState = .disconnected
        isDemoMode = false
    }

    // MARK: - Saved Devices

    func removeSavedDevice(_ device: TVDevice) {
        savedDevices.removeAll { $0.id == device.id }
        persistDevices()
    }

    private func saveDevice(_ device: TVDevice) {
        savedDevices.removeAll { $0.id == device.id }
        savedDevices.insert(device, at: 0)
        if savedDevices.count > 10 { savedDevices = Array(savedDevices.prefix(10)) }
        persistDevices()
    }

    private func persistDevices() {
        if let data = try? JSONEncoder().encode(savedDevices) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }

    private func loadSavedDevices() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([TVDevice].self, from: data) else { return }
        savedDevices = decoded
    }

    private func attemptReconnect() {
        guard let last = savedDevices.first else { return }
        isReconnecting = true
        Task {
            await connect(to: last)
            isReconnecting = false
        }
    }

    // MARK: - Commands

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

// MARK: - Demo Protocol

class DemoProtocol: NSObject, TVProtocol {
    let device: TVDevice
    private(set) var isConnected = true

    init(device: TVDevice) { self.device = device }

    func connect() async throws {}
    func disconnect() { isConnected = false }
    func sendKey(_ key: RemoteKey) async throws {}
    func sendText(_ text: String) async throws {}
    func sendMouseMove(dx: Float, dy: Float) async throws {}
    func sendMouseClick() async throws {}
    func sendMouseScroll(delta: Float) async throws {}
    func getApps() async throws -> [TVApp] {
        return [
            TVApp(id: "netflix", name: "Netflix", iconURL: nil),
            TVApp(id: "youtube", name: "YouTube", iconURL: nil),
            TVApp(id: "prime", name: "Prime Video", iconURL: nil),
            TVApp(id: "spotify", name: "Spotify", iconURL: nil),
            TVApp(id: "disney", name: "Disney+", iconURL: nil),
            TVApp(id: "appletv", name: "Apple TV", iconURL: nil),
        ]
    }
    func launchApp(_ app: TVApp) async throws {}
}
