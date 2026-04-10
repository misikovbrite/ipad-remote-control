import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var discovery = TVDiscoveryService()
    @StateObject private var connectionManager = TVConnectionManager()

    var body: some View {
        Group {
            if connectionManager.connectedDevice != nil {
                RemoteControlView()
                    .environmentObject(connectionManager)
            } else {
                DeviceListView(discovery: discovery, connectionManager: connectionManager)
            }
        }
        .onAppear { discovery.startScan() }
    }
}
