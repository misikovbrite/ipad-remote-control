import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var connectedDevice: TVDevice?
    @Published var discoveredDevices: [TVDevice] = []
    @Published var isScanning = false
    @Published var showKeyboard = false
    @Published var showTouchpad = false
    @Published var isPremium = false
    @Published var showPaywall = false
}
