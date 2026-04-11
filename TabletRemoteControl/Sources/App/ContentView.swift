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
                    discovery.startScan()
                }
            } else if connectionManager.connectedDevice != nil {
                RemoteControlView()
                    .environmentObject(connectionManager)
            } else {
                MainTabView(discovery: discovery, connectionManager: connectionManager)
            }
        }
        .onAppear {
            if hasSeenOnboarding { discovery.startScan() }
        }
    }
}
