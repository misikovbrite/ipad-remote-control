import SwiftUI

// MARK: - Main Tab Container

struct MainTabView: View {
    @ObservedObject var discovery: TVDiscoveryService
    @ObservedObject var connectionManager: TVConnectionManager

    var body: some View {
        TabView {
            DeviceListView(discovery: discovery, connectionManager: connectionManager)
                .tabItem { Label("Devices", systemImage: "tv.and.mediabox") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.indigo)
    }
}

// MARK: - Device List

struct DeviceListView: View {
    @ObservedObject var discovery: TVDiscoveryService
    @ObservedObject var connectionManager: TVConnectionManager

    @State private var connectingID: String?
    @State private var showManualAdd = false
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            Group {
                if isScanning || !discovery.devices.isEmpty {
                    scanView
                } else {
                    homeView
                }
            }
            .navigationTitle("Tablet Remote")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showManualAdd) {
            ManualAddDeviceView(connectionManager: connectionManager)
        }
    }

    // MARK: Home Screen

    private var homeView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.1))
                            .frame(width: 110, height: 110)
                        Image(systemName: "tv.and.mediabox")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.indigo)
                    }
                    Text("Tablet Remote")
                        .font(.largeTitle.bold())
                    Text("Turn your iPad into a universal TV remote")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Saved devices
                if !connectionManager.savedDevices.isEmpty {
                    savedSection
                }

                // Action buttons
                VStack(spacing: 14) {
                    ActionButton(
                        icon: "wifi",
                        title: "Search for TV",
                        subtitle: "Scan your Wi-Fi network",
                        style: .primary
                    ) {
                        isScanning = true
                        discovery.startScan()
                    }

                    ActionButton(
                        icon: "plus.circle",
                        title: "Add TV Manually",
                        subtitle: "Enter IP address",
                        style: .secondary
                    ) {
                        showManualAdd = true
                    }

                    ActionButton(
                        icon: "play.circle",
                        title: "Try Demo Mode",
                        subtitle: "Preview the remote without a TV",
                        style: .ghost
                    ) {
                        connectionManager.connectDemo()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal, 32)

            VStack(spacing: 0) {
                ForEach(connectionManager.savedDevices) { device in
                    SavedDeviceRow(device: device, isConnecting: connectingID == device.id) {
                        connectTo(device)
                    } onDelete: {
                        connectionManager.removeSavedDevice(device)
                    }
                    if device.id != connectionManager.savedDevices.last?.id {
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: Scan Results

    private var scanView: some View {
        List {
            if discovery.isScanning {
                Section {
                    HStack(spacing: 12) {
                        ProgressView().tint(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scanning your network…")
                                .font(.subheadline.weight(.medium))
                            Text("This may take 15–30 seconds")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if !discovery.devices.isEmpty {
                Section("Found on your network") {
                    ForEach(discovery.devices) { device in
                        DeviceRow(device: device, isConnecting: connectingID == device.id) {
                            connectTo(device)
                        }
                    }
                }
            }

            if !discovery.isScanning && discovery.devices.isEmpty {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No TVs found")
                            .font(.headline)
                        Text("Make sure your TV is on and connected to the same Wi-Fi network.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Button { discovery.startScan() } label: {
                    Label("Scan Again", systemImage: "arrow.clockwise").foregroundStyle(.indigo)
                }
                Button { showManualAdd = true } label: {
                    Label("Add TV Manually", systemImage: "plus.circle").foregroundStyle(.indigo)
                }
                Button {
                    isScanning = false
                    discovery.stopScan()
                } label: {
                    Label("Back to Home", systemImage: "house").foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func connectTo(_ device: TVDevice) {
        connectingID = device.id
        Task {
            await connectionManager.connect(to: device)
            connectingID = nil
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    enum Style { case primary, secondary, ghost }

    let icon: String
    let title: String
    let subtitle: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(titleColor)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .indigo
        case .ghost: return .secondary
        }
    }

    private var titleColor: Color {
        switch style {
        case .primary: return .white
        case .secondary, .ghost: return .primary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient(colors: [.indigo, Color(hex: "5856D6")],
                           startPoint: .leading, endPoint: .trailing)
        case .secondary:
            Color.indigo.opacity(0.08)
        case .ghost:
            Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return .indigo.opacity(0.2)
        case .ghost: return .clear
        }
    }
}

// MARK: - Saved Device Row

struct SavedDeviceRow: View {
    let device: TVDevice
    let isConnecting: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: device.brand.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(device.brand.rawValue) · \(device.ipAddress)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isConnecting {
                ProgressView()
            } else {
                Button(action: onTap) {
                    Text("Connect")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.indigo, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

// MARK: - Device Row (scan results)

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
    @State private var showPairingHint = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("IP Address", systemImage: "network")
                        Spacer()
                        TextField("192.168.1.100", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Device Name", systemImage: "tv")
                        Spacer()
                        TextField("Optional", text: $deviceName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Find your TV's IP address in its network settings menu.")
                }

                Section("TV Brand") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 10) {
                        ForEach(TVBrand.allCases.filter { $0 != .unknown }, id: \.self) { brand in
                            brandCell(brand)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Samsung pairing hint
                if selectedBrand == .samsung || selectedBrand == .lg {
                    Section {
                        Label {
                            Text("Your TV will show an approval dialog on screen — accept it to complete pairing.")
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "tv.badge.wifi")
                                .foregroundStyle(.blue)
                        }
                    } header: {
                        Text("Pairing")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    Button { addDevice() } label: {
                        HStack {
                            Spacer()
                            if isConnecting {
                                VStack(spacing: 6) {
                                    ProgressView().tint(.white)
                                    if selectedBrand == .samsung || selectedBrand == .lg {
                                        Text("Check your TV screen…")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                            } else {
                                Label("Connect", systemImage: "wifi")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(ipAddress.isEmpty ? Color(.systemGray4) : Color.indigo)
                    .disabled(ipAddress.isEmpty || isConnecting)
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

    private func brandCell(_ brand: TVBrand) -> some View {
        let isSelected = selectedBrand == brand
        return Button { selectedBrand = brand } label: {
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
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.indigo : Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }

    private func addDevice() {
        let ip = ipAddress.trimmingCharacters(in: .whitespaces)
        guard !ip.isEmpty else { return }
        let name = deviceName.isEmpty ? "\(selectedBrand.rawValue) TV" : deviceName
        let device = TVDevice(
            id: "\(ip):\(selectedBrand.defaultPort)",
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
                    errorMessage = "Could not connect. Check the IP address and make sure the TV is powered on."
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Premium") {
                    if SubscriptionService.shared.isPro {
                        Label("Premium Active", systemImage: "crown.fill")
                            .foregroundStyle(.indigo)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "crown.fill")
                                .foregroundStyle(.indigo)
                        }
                    }
                }

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
                        Label(name, systemImage: icon).foregroundStyle(color)
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
                    LabeledContent("Version", value: "1.1")
                    LabeledContent("Build", value: "2")
                }
            }
            .navigationTitle("Settings")
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(
                subscriptionService: SubscriptionService.shared,
                onDismiss: { showPaywall = false }
            )
        }
    }
}

// MARK: - Color Extension

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
