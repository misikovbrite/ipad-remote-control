import SwiftUI

struct RemoteControlView: View {
    @EnvironmentObject var connectionManager: TVConnectionManager
    @State private var activeTab: RemoteTab = .remote
    @State private var showKeyboard = false
    @State private var showTouchpad = false

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
                    AppsGridView()
                        .environmentObject(connectionManager)
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
                    HStack(spacing: 10) {
                        Button {
                            showTouchpad = true
                        } label: {
                            Label("Touchpad", systemImage: "hand.point.up.left.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.indigo)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)

                        Button {
                            showKeyboard = true
                        } label: {
                            Label("Keyboard", systemImage: "keyboard")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.blue)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)

                        Button {
                            connectionManager.disconnect()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showKeyboard) {
            TVKeyboardView { text in
                connectionManager.sendText(text)
            }
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTouchpad) {
            TVTouchpadView(connectionManager: connectionManager)
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
        }
    }

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
        .padding(.vertical, 10)
        .background(Color.orange)
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(.green)
                .frame(width: 7, height: 7)
            Text("Connected")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6), in: Capsule())
    }

    private var remoteContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                powerVolumeRow
                navigationPad
                playbackControls
                numberPad
                streamingRow
            }
            .padding(20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Power & Volume

    private var powerVolumeRow: some View {
        HStack(spacing: 16) {
            RemoteButton(icon: "power", label: "Power", color: .red, size: .large) {
                connectionManager.sendKey(.power)
            }
            Spacer()
            card {
                VStack(spacing: 10) {
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
                .padding(.vertical, 8)
            }
            card {
                VStack(spacing: 10) {
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
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Nav Pad

    private var navigationPad: some View {
        VStack(spacing: 0) {
            RemoteButton(icon: "chevron.up", label: nil, color: .primary, size: .navArrow) {
                connectionManager.sendKey(.up)
            }
            HStack(spacing: 0) {
                RemoteButton(icon: "chevron.left", label: nil, color: .primary, size: .navArrow) {
                    connectionManager.sendKey(.left)
                }
                Button {
                    connectionManager.sendKey(.enter)
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .blue],
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

            HStack(spacing: 40) {
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
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Playback

    private var playbackControls: some View {
        HStack(spacing: 0) {
            Spacer()
            RemoteButton(icon: "backward.fill", label: "Rewind", color: .secondary, size: .medium) {
                connectionManager.sendKey(.rewind)
            }
            Spacer()
            RemoteButton(icon: "play.fill", label: "Play", color: .green, size: .medium) {
                connectionManager.sendKey(.play)
            }
            Spacer()
            RemoteButton(icon: "pause.fill", label: "Pause", color: .orange, size: .medium) {
                connectionManager.sendKey(.pause)
            }
            Spacer()
            RemoteButton(icon: "stop.fill", label: "Stop", color: .red, size: .medium) {
                connectionManager.sendKey(.stop)
            }
            Spacer()
            RemoteButton(icon: "forward.fill", label: "Forward", color: .secondary, size: .medium) {
                connectionManager.sendKey(.fastForward)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Numpad

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach([RemoteKey.num1, .num2, .num3,
                     .num4, .num5, .num6,
                     .num7, .num8, .num9], id: \.rawValue) { key in
                numButton(key.rawValue) { connectionManager.sendKey(key) }
            }
            Color.clear
            numButton("0") { connectionManager.sendKey(.num0) }
            Color.clear
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func numButton(_ label: String, action: @escaping () -> Void) -> some View {
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

    // MARK: - Streaming

    private var streamingRow: some View {
        HStack(spacing: 12) {
            StreamingButton(name: "Netflix", color: .red) {
                connectionManager.sendKey(.netflix)
            }
            StreamingButton(name: "YouTube", color: .red) {
                connectionManager.sendKey(.youtube)
            }
            StreamingButton(name: "Prime", color: .blue) {
                connectionManager.sendKey(.prime)
            }
            Spacer()
            RemoteButton(icon: "rectangle.on.rectangle", label: "Source", color: .secondary, size: .medium) {
                connectionManager.sendKey(.source)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Helpers

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - RemoteButton

enum RemoteButtonSize {
    case small, medium, large, navArrow
    var diameter: CGFloat {
        switch self {
        case .small:    return 44
        case .medium:   return 52
        case .large:    return 62
        case .navArrow: return 54
        }
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
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
