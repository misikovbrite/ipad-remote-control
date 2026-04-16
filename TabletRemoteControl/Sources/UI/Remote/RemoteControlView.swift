import SwiftUI

struct RemoteControlView: View {
    @EnvironmentObject var connectionManager: TVConnectionManager
    @State private var activeTab: RemoteTab = .remote
    @State private var showKeyboard = false
    @State private var showTouchpad = false
    @State private var showPremiumPaywall = false

    private let subscriptionService = SubscriptionService.shared

    enum RemoteTab { case remote, apps }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if connectionManager.isDemoMode {
                    demoBanner
                }

                Picker("", selection: $activeTab) {
                    Text("Remote").tag(RemoteTab.remote)
                    Text("Apps").tag(RemoteTab.apps)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))

                Divider()

                if activeTab == .remote {
                    remoteContent
                } else {
                    appsTabContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(connectionManager.connectedDevice?.name ?? "Remote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    statusBadge
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        toolbarIconButton(icon: "hand.point.up.left.fill", color: .indigo) {
                            if FeatureGate.canAccess(.touchpad, subscriptionService: subscriptionService) {
                                showTouchpad = true
                            } else {
                                showPremiumPaywall = true
                            }
                        }
                        toolbarIconButton(icon: "keyboard", color: .blue) {
                            if FeatureGate.canAccess(.keyboard, subscriptionService: subscriptionService) {
                                showKeyboard = true
                            } else {
                                showPremiumPaywall = true
                            }
                        }
                        Button { connectionManager.disconnect() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showKeyboard) {
            TVKeyboardView { text in connectionManager.sendText(text) }
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTouchpad) {
            TVTouchpadView(connectionManager: connectionManager)
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showPremiumPaywall) {
            PaywallView(subscriptionService: subscriptionService, onDismiss: { showPremiumPaywall = false })
        }
    }

    // MARK: - Apps tab content

    @ViewBuilder
    private var appsTabContent: some View {
        if FeatureGate.canAccess(.appsGrid, subscriptionService: subscriptionService) {
            AppsGridView().environmentObject(connectionManager)
        } else {
            ScrollView {
                PremiumBannerView(featureName: "Apps Grid") {
                    showPremiumPaywall = true
                }
                .padding(.top, 40)
            }
        }
    }

    // MARK: - Toolbar icon button

    private func toolbarIconButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: Circle())
        }
    }

    // MARK: - Demo Banner

    private var demoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
                .foregroundStyle(.white)
            Text("Demo Mode — buttons don't control a real TV")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.orange)
    }

    // MARK: - Status badge

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle().fill(.green).frame(width: 7, height: 7)
            Text("Connected")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6), in: Capsule())
    }

    // MARK: - Remote content

    private var remoteContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                topControlsRow
                navigationPad
                playbackControls
                numberPad
                streamingRow
            }
            .padding(16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Top controls: Power | Vol | Ch

    private var topControlsRow: some View {
        HStack(spacing: 14) {
            // Power + Source
            VStack(spacing: 10) {
                RemoteButton(icon: "power", label: "Power", color: .red, size: .large) {
                    connectionManager.sendKey(.power)
                }
                RemoteButton(icon: "rectangle.on.rectangle", label: "Source", color: .indigo, size: .medium) {
                    connectionManager.sendKey(.source)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

            // Volume
            VStack(spacing: 10) {
                Text("Volume")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                RemoteButton(icon: "speaker.plus.fill", label: "Vol +", color: .indigo, size: .medium) {
                    connectionManager.sendKey(.volumeUp)
                }
                RemoteButton(icon: "speaker.slash.fill", label: "Mute", color: .orange, size: .medium) {
                    connectionManager.sendKey(.mute)
                }
                RemoteButton(icon: "speaker.minus.fill", label: "Vol −", color: .indigo, size: .medium) {
                    connectionManager.sendKey(.volumeDown)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

            // Channel
            VStack(spacing: 10) {
                Text("Channel")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                RemoteButton(icon: "chevron.up", label: "Ch +", color: .purple, size: .medium) {
                    connectionManager.sendKey(.channelUp)
                }
                RemoteButton(icon: "list.bullet", label: "Guide", color: .purple, size: .medium) {
                    connectionManager.sendKey(.menu)
                }
                RemoteButton(icon: "chevron.down", label: "Ch −", color: .purple, size: .medium) {
                    connectionManager.sendKey(.channelDown)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
    }

    // MARK: - Navigation pad

    private var navigationPad: some View {
        VStack(spacing: 0) {
            RemoteButton(icon: "chevron.up", label: nil, color: .primary, size: .navArrow) {
                connectionManager.sendKey(.up)
            }
            HStack(spacing: 0) {
                RemoteButton(icon: "chevron.left", label: nil, color: .primary, size: .navArrow) {
                    connectionManager.sendKey(.left)
                }
                Button { connectionManager.sendKey(.enter) } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, Color(hex: "5856D6")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 76, height: 76)
                            .shadow(color: .indigo.opacity(0.35), radius: 8, y: 4)
                        Text("OK")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                RemoteButton(icon: "chevron.right", label: nil, color: .primary, size: .navArrow) {
                    connectionManager.sendKey(.right)
                }
            }
            RemoteButton(icon: "chevron.down", label: nil, color: .primary, size: .navArrow) {
                connectionManager.sendKey(.down)
            }
            Divider().padding(.vertical, 10)
            HStack(spacing: 48) {
                RemoteButton(icon: "house.fill", label: "Home", color: .indigo, size: .small) {
                    connectionManager.sendKey(.home)
                }
                RemoteButton(icon: "arrow.uturn.left", label: "Back", color: .secondary, size: .small) {
                    connectionManager.sendKey(.back)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Playback

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Spacer()
            RemoteButton(icon: "backward.fill",  label: "Rewind",  color: .secondary, size: .medium) { connectionManager.sendKey(.rewind) }
            Spacer()
            RemoteButton(icon: "play.fill",      label: "Play",    color: .green,     size: .medium) { connectionManager.sendKey(.play) }
            Spacer()
            RemoteButton(icon: "pause.fill",     label: "Pause",   color: .orange,    size: .medium) { connectionManager.sendKey(.pause) }
            Spacer()
            RemoteButton(icon: "stop.fill",      label: "Stop",    color: .red,       size: .medium) { connectionManager.sendKey(.stop) }
            Spacer()
            RemoteButton(icon: "forward.fill",   label: "Forward", color: .secondary, size: .medium) { connectionManager.sendKey(.fastForward) }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Number pad

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach([RemoteKey.num1, .num2, .num3,
                     .num4, .num5, .num6,
                     .num7, .num8, .num9], id: \.rawValue) { key in
                numKey(key.rawValue) { connectionManager.sendKey(key) }
            }
            Color.clear
            numKey("0") { connectionManager.sendKey(.num0) }
            Color.clear
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func numKey(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streaming row

    private var streamingRow: some View {
        HStack(spacing: 12) {
            StreamingButton(name: "Netflix", color: Color(hex: "E50914")) { connectionManager.sendKey(.netflix) }
            StreamingButton(name: "YouTube", color: Color(hex: "FF0000")) { connectionManager.sendKey(.youtube) }
            StreamingButton(name: "Prime",   color: Color(hex: "00A8E0")) { connectionManager.sendKey(.prime) }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - RemoteButton

enum RemoteButtonSize {
    case small, medium, large, navArrow
    var diameter: CGFloat {
        switch self { case .small: return 44; case .medium: return 52; case .large: return 62; case .navArrow: return 54 }
    }
    var iconScale: CGFloat { diameter * 0.36 }
}

struct RemoteButton: View {
    let icon: String
    let label: String?
    let color: Color
    let size: RemoteButtonSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: size.iconScale, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: size.diameter, height: size.diameter)
                    .background(Color(.systemGray6), in: Circle())
                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StreamingButton

struct StreamingButton: View {
    let name: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
