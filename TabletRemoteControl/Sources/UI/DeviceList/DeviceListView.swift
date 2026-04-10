import SwiftUI

struct DeviceListView: View {
    @ObservedObject var discovery: TVDiscoveryService
    @ObservedObject var connectionManager: TVConnectionManager
    @State private var isConnecting = false
    @State private var connectingID: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0F1A").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "tv.and.mediabox")
                            .font(.system(size: 52))
                            .foregroundStyle(LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .padding(.top, 40)
                        Text("Tablet Remote Control")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Connect to your Smart TV")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 40)

                    // Scanning indicator
                    if discovery.isScanning {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.purple)
                            Text("Scanning network...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                    }

                    // Device list
                    if discovery.devices.isEmpty && !discovery.isScanning {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(discovery.devices) { device in
                                    DeviceRow(
                                        device: device,
                                        isConnecting: connectingID == device.id
                                    ) {
                                        connectTo(device)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer()

                    // Manual add / rescan
                    Button {
                        discovery.startScan()
                    } label: {
                        Label("Rescan Network", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.purple)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.5))
            Text("No TVs found")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Make sure your TV and iPad\nare on the same Wi-Fi network")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private func connectTo(_ device: TVDevice) {
        connectingID = device.id
        Task {
            await connectionManager.connect(to: device)
            connectingID = nil
        }
    }
}

struct DeviceRow: View {
    let device: TVDevice
    let isConnecting: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: brandColors(device.brand),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                    Image(systemName: device.brand.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(device.brand.rawValue) · \(device.ipAddress)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if isConnecting {
                    ProgressView()
                        .tint(.purple)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
    }

    private func brandColors(_ brand: TVBrand) -> [Color] {
        switch brand {
        case .samsung: return [.blue, .cyan]
        case .lg: return [.red, .orange]
        case .sony: return [.gray, .white.opacity(0.8)]
        case .roku: return [.purple, .indigo]
        case .appleTV: return [.white.opacity(0.8), .gray]
        case .androidTV: return [.green, .teal]
        case .philips: return [.blue, .indigo]
        case .fireTV: return [.orange, .red]
        case .unknown: return [.gray, .gray.opacity(0.7)]
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
