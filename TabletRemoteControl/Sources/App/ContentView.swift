import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var discovery = TVDiscoveryService()
    @StateObject private var connectionManager = TVConnectionManager()

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            } else if connectionManager.isReconnecting {
                ReconnectingView(deviceName: connectionManager.savedDevices.first?.name ?? "TV")
            } else if connectionManager.connectedDevice != nil {
                RemoteControlView()
                    .environmentObject(connectionManager)
            } else {
                MainTabView(discovery: discovery, connectionManager: connectionManager)
            }
        }
    }
}

// MARK: - Reconnecting splash

struct ReconnectingView: View {
    let deviceName: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.indigo)
            Text("Reconnecting to \(deviceName)…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
