import SwiftUI

// MARK: - Main Tab Container

struct MainTabView: View {
    @ObservedObject var discovery: TVDiscoveryService
    @ObservedObject var connectionManager: TVConnectionManager

    var body: some View {
        TabView {
            DeviceListView(discovery: discovery, connectionManager: connectionManager)
                .tabItem {
                    Label("Devices", systemImage: "tv.and.mediabox")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.purple)
    }
}

// MARK: - Device List Tab

struct DeviceListView: View {
    @ObservedObject var discovery: TVDiscoveryService
    @ObservedObject var connectionManager: TVConnectionManager
    @State private var connectingID: String?
    @State private var showManualAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0F1A").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scanning indicator
                    if discovery.isScanning {
                        HStack(spacing: 10) {
                            ProgressView().tint(.purple)
                            Text("Scanning network…")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                    }

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
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }

                    Spacer()

                    Button {
                        discovery.startScan()
                    } label: {
                        Label("Rescan Network", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.purple)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Find Your TV")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showManualAdd = true
                    } label: {
                        Label("Add Manually", systemImage: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .sheet(isPresented: $showManualAdd) {
            ManualAddDeviceView(connectionManager: connectionManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 52))
                .foregroundColor(.gray.opacity(0.4))
            Text("No TVs found")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Make sure your TV and iPad\nare on the same Wi-Fi network")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button {
                showManualAdd = true
            } label: {
                Label("Add TV Manually", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple.opacity(0.3))
                    .overlay(Capsule().stroke(Color.purple.opacity(0.6), lineWidth: 1))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 60)
    }

    private func connectTo(_ device: TVDevice) {
        connectingID = device.id
        Task {
            await connectionManager.connect(to: device)
            connectingID = nil
        }
    }
}

// MARK: - Manual Add Sheet

struct ManualAddDeviceView: View {
    @ObservedObject var connectionManager: TVConnectionManager
    @Environment(\.dismiss) private var dismiss

    @State private var ipAddress = ""
    @State private var deviceName = ""
    @State private var selectedBrand: TVBrand = .samsung
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0F1A").ignoresSafeArea()
                ScrollView {
                    formContent
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var formContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "tv.badge.wifi")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .padding(.top, 16)

            Text("Add TV Manually")
                .font(.title2.bold())
                .foregroundColor(.white)

            ipField
            nameField
            brandPicker

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            connectButton
        }
    }

    private var ipField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IP Address")
                .font(.caption.weight(.semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            TextField("192.168.1.100", text: $ipAddress)
                .keyboardType(.decimalPad)
                .font(.body)
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .padding(.horizontal, 16)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Name (optional)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            TextField("Living Room TV", text: $deviceName)
                .font(.body)
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .padding(.horizontal, 16)
        }
    }

    private var brandPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TV Brand")
                .font(.caption.weight(.semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TVBrand.allCases, id: \.self) { brand in
                        brandCell(brand)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func brandCell(_ brand: TVBrand) -> some View {
        let isSelected = selectedBrand == brand
        return Button {
            selectedBrand = brand
        } label: {
            VStack(spacing: 6) {
                Image(systemName: brand.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .gray)
                Text(brand.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple.opacity(0.8) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var connectButton: some View {
        Button {
            addDevice()
        } label: {
            HStack {
                if isConnecting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "wifi")
                    Text("Connect")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(connectButtonBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(ipAddress.isEmpty || isConnecting)
        .padding(.horizontal, 20)
    }

    private var connectButtonBg: some ShapeStyle {
        if ipAddress.isEmpty {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        }
        return AnyShapeStyle(LinearGradient(colors: [.purple, .blue],
                                            startPoint: .leading, endPoint: .trailing))
    }

    private func addDevice() {
        let ip = ipAddress.trimmingCharacters(in: .whitespaces)
        guard !ip.isEmpty else { return }

        let name = deviceName.isEmpty ? "\(selectedBrand.rawValue) TV" : deviceName
        let port = selectedBrand.defaultPort
        let device = TVDevice(
            id: UUID().uuidString,
            name: name,
            brand: selectedBrand,
            ipAddress: ip,
            port: port,
            modelName: nil,
            connectionState: .disconnected
        )

        isConnecting = true
        errorMessage = nil
        Task {
            await connectionManager.connect(to: device)
            await MainActor.run {
                isConnecting = false
                if connectionManager.connectedDevice != nil {
                    dismiss()
                } else {
                    errorMessage = "Could not connect. Check the IP and make sure the TV is on."
                }
            }
        }
    }
}

// MARK: - Settings Tab

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0F1A").ignoresSafeArea()

                List {
                    Section {
                        settingsRow(icon: "tv.and.mediabox", iconColor: .purple, title: "Supported TVs") {
                            Text("Samsung, LG, Sony, Roku, Apple TV, Android TV, Fire TV, Philips")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("About")
                            .foregroundColor(.gray)
                    }

                    Section {
                        Button {
                            hasSeenOnboarding = false
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .frame(width: 28, height: 28)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                Text("Replay Onboarding")
                                    .foregroundColor(.white)
                            }
                        }
                    } header: {
                        Text("Onboarding")
                            .foregroundColor(.gray)
                    }

                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .frame(width: 28, height: 28)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tablet Remote")
                                    .foregroundColor(.white)
                                Text("Version 1.0")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    } header: {
                        Text("App")
                            .foregroundColor(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.white.opacity(0.07))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func settingsRow(icon: String, iconColor: Color, title: String, @ViewBuilder detail: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.2))
                .foregroundColor(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                detail()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Device Row

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
                    ProgressView().tint(.purple)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1))
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
