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
        .tint(.indigo)
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
            Group {
                if discovery.devices.isEmpty && !discovery.isScanning {
                    emptyState
                } else {
                    deviceList
                }
            }
            .navigationTitle("Find Your TV")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showManualAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        discovery.startScan()
                    } label: {
                        Label("Rescan", systemImage: "arrow.clockwise")
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                if discovery.isScanning {
                    scanningBanner
                }
            }
        }
        .sheet(isPresented: $showManualAdd) {
            ManualAddDeviceView(connectionManager: connectionManager)
        }
    }

    private var scanningBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.indigo)
            Text("Scanning your network…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var deviceList: some View {
        List {
            Section {
                ForEach(discovery.devices) { device in
                    DeviceRow(device: device, isConnecting: connectingID == device.id) {
                        connectTo(device)
                    }
                }
            } header: {
                Text("Found on your network")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No TVs Found", systemImage: "tv.slash")
        } description: {
            Text("Make sure your TV and iPad are on the same Wi-Fi network, then try rescanning.")
        } actions: {
            VStack(spacing: 12) {
                Button {
                    discovery.startScan()
                } label: {
                    Label("Scan Network", systemImage: "arrow.clockwise")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button {
                    showManualAdd = true
                } label: {
                    Label("Add TV Manually", systemImage: "plus")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.bordered)
                .tint(.indigo)
            }
        }
    }

    private func connectTo(_ device: TVDevice) {
        connectingID = device.id
        Task {
            await connectionManager.connect(to: device)
            connectingID = nil
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: TVDevice
    let isConnecting: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(brandGradient(device.brand))
                        .frame(width: 48, height: 48)
                    Image(systemName: device.brand.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(device.brand.rawValue) · \(device.ipAddress)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isConnecting {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
    }

    private func brandGradient(_ brand: TVBrand) -> LinearGradient {
        let colors: [Color] = {
            switch brand {
            case .samsung:   return [Color(hex: "1428A0"), Color(hex: "0077C8")]
            case .lg:        return [Color(hex: "A50034"), Color(hex: "E0002B")]
            case .sony:      return [.gray, Color(hex: "888888")]
            case .roku:      return [Color(hex: "6F2DA8"), Color(hex: "9B59B6")]
            case .appleTV:   return [Color(hex: "444444"), Color(hex: "222222")]
            case .androidTV: return [Color(hex: "3DDC84"), Color(hex: "00897B")]
            case .philips:   return [Color(hex: "0058A9"), Color(hex: "003D7A")]
            case .fireTV:    return [Color(hex: "FF9900"), Color(hex: "E47911")]
            case .unknown:   return [.gray, Color(hex: "888888")]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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
            Form {
                Section("Connection") {
                    HStack {
                        Label("IP Address", systemImage: "network")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("192.168.1.100", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Device Name", systemImage: "tv")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("Optional", text: $deviceName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("TV Brand") {
                    brandPickerGrid
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    connectButton
                }
            }
            .navigationTitle("Add TV Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var brandPickerGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
            ForEach(TVBrand.allCases.filter { $0 != .unknown }, id: \.self) { brand in
                brandCell(brand)
            }
        }
        .padding(.vertical, 6)
    }

    private func brandCell(_ brand: TVBrand) -> some View {
        let isSelected = selectedBrand == brand
        return Button {
            selectedBrand = brand
        } label: {
            VStack(spacing: 6) {
                Image(systemName: brand.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text(brand.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.indigo : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    private var connectButton: some View {
        Button {
            addDevice()
        } label: {
            HStack {
                Spacer()
                if isConnecting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Connect", systemImage: "wifi")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(ipAddress.isEmpty ? Color(.systemGray4) : Color.indigo)
        .disabled(ipAddress.isEmpty || isConnecting)
    }

    private func addDevice() {
        let ip = ipAddress.trimmingCharacters(in: .whitespaces)
        guard !ip.isEmpty else { return }
        let name = deviceName.isEmpty ? "\(selectedBrand.rawValue) TV" : deviceName
        let device = TVDevice(
            id: UUID().uuidString,
            name: name,
            brand: selectedBrand,
            ipAddress: ip,
            port: selectedBrand.defaultPort,
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
            Form {
                Section("Supported Brands") {
                    ForEach([
                        ("Samsung", "tv", Color(hex: "1428A0")),
                        ("LG", "tv", Color(hex: "A50034")),
                        ("Sony", "tv", Color.gray),
                        ("Roku", "tv.and.mediabox", Color(hex: "6F2DA8")),
                        ("Apple TV", "appletv", Color(hex: "444444")),
                        ("Android TV", "tv", Color(hex: "3DDC84")),
                        ("Fire TV", "flame", Color(hex: "FF9900")),
                        ("Philips", "tv", Color(hex: "0058A9")),
                    ], id: \.0) { name, icon, color in
                        Label(name, systemImage: icon)
                            .foregroundStyle(color)
                    }
                }

                Section {
                    Button {
                        hasSeenOnboarding = false
                    } label: {
                        Label("Replay Introduction", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Onboarding")
                } footer: {
                    Text("Shows the welcome screens again on next launch.")
                }

                Section("App Info") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Color extension

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
