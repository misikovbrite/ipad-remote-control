import SwiftUI

struct RemoteControlView: View {
    @EnvironmentObject var connectionManager: TVConnectionManager
    @State private var activeTab: RemoteTab = .remote
    @State private var showKeyboard = false
    @State private var showTouchpad = false

    enum RemoteTab { case remote, apps }

    var body: some View {
        ZStack {
            Color(hex: "0F0F1A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Tab switcher
                Picker("", selection: $activeTab) {
                    Text("Remote").tag(RemoteTab.remote)
                    Text("Apps").tag(RemoteTab.apps)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Content
                if activeTab == .remote {
                    remoteContent
                } else {
                    AppsGridView()
                        .environmentObject(connectionManager)
                }
            }

            // Floating keyboard button
            if activeTab == .remote {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingButtons
                            .padding(.trailing, 28)
                            .padding(.bottom, 32)
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

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(connectionManager.connectedDevice?.name ?? "TV")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            Spacer()
            Button {
                connectionManager.disconnect()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var remoteContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Power + Volume row
                powerVolumeRow
                // Navigation pad
                navigationPad
                // Playback controls
                playbackControls
                // Number pad
                numberPad
                // Source / streaming apps row
                streamingRow
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }

    private var powerVolumeRow: some View {
        HStack(spacing: 20) {
            RemoteButton(icon: "power", color: .red, size: .large) {
                connectionManager.sendKey(.power)
            }
            Spacer()
            VStack(spacing: 12) {
                RemoteButton(icon: "speaker.plus.fill", color: .blue, size: .medium) {
                    connectionManager.sendKey(.volumeUp)
                }
                RemoteButton(icon: "speaker.slash.fill", color: .orange, size: .medium) {
                    connectionManager.sendKey(.mute)
                }
                RemoteButton(icon: "speaker.minus.fill", color: .blue, size: .medium) {
                    connectionManager.sendKey(.volumeDown)
                }
            }
            Spacer()
            VStack(spacing: 12) {
                RemoteButton(icon: "chevron.up", color: .purple, size: .medium) {
                    connectionManager.sendKey(.channelUp)
                }
                RemoteButton(icon: "list.bullet", color: .purple, size: .medium) {
                    connectionManager.sendKey(.menu)
                }
                RemoteButton(icon: "chevron.down", color: .purple, size: .medium) {
                    connectionManager.sendKey(.channelDown)
                }
            }
        }
        .padding(20)
        .background(glassBackground)
    }

    private var navigationPad: some View {
        VStack(spacing: 0) {
            // Up
            RemoteButton(icon: "chevron.up", color: .white, size: .navArrow) {
                connectionManager.sendKey(.up)
            }
            HStack(spacing: 0) {
                RemoteButton(icon: "chevron.left", color: .white, size: .navArrow) {
                    connectionManager.sendKey(.left)
                }
                // Center OK button
                Button {
                    connectionManager.sendKey(.enter)
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Text("OK")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                RemoteButton(icon: "chevron.right", color: .white, size: .navArrow) {
                    connectionManager.sendKey(.right)
                }
            }
            RemoteButton(icon: "chevron.down", color: .white, size: .navArrow) {
                connectionManager.sendKey(.down)
            }

            // Home / Back row
            HStack(spacing: 28) {
                RemoteButton(icon: "house.fill", color: .gray, size: .small) {
                    connectionManager.sendKey(.home)
                }
                RemoteButton(icon: "arrow.uturn.left", color: .gray, size: .small) {
                    connectionManager.sendKey(.back)
                }
            }
            .padding(.top, 16)
        }
        .padding(24)
        .background(glassBackground)
    }

    private var playbackControls: some View {
        HStack(spacing: 20) {
            RemoteButton(icon: "backward.fill", color: .gray, size: .medium) {
                connectionManager.sendKey(.rewind)
            }
            RemoteButton(icon: "play.fill", color: .green, size: .medium) {
                connectionManager.sendKey(.play)
            }
            RemoteButton(icon: "pause.fill", color: .yellow, size: .medium) {
                connectionManager.sendKey(.pause)
            }
            RemoteButton(icon: "stop.fill", color: .red, size: .medium) {
                connectionManager.sendKey(.stop)
            }
            RemoteButton(icon: "forward.fill", color: .gray, size: .medium) {
                connectionManager.sendKey(.fastForward)
            }
        }
        .padding(20)
        .background(glassBackground)
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach([RemoteKey.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9], id: \.rawValue) { key in
                Button {
                    connectionManager.sendKey(key)
                } label: {
                    Text(key.rawValue)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            Color.clear.frame(height: 56)
            Button {
                connectionManager.sendKey(.num0)
            } label: {
                Text("0")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            Color.clear.frame(height: 56)
        }
        .padding(20)
        .background(glassBackground)
    }

    private var streamingRow: some View {
        HStack(spacing: 16) {
            StreamingButton(name: "Netflix", color: .red) {
                connectionManager.sendKey(.netflix)
            }
            StreamingButton(name: "YouTube", color: .red) {
                connectionManager.sendKey(.youtube)
            }
            StreamingButton(name: "Prime", color: .blue) {
                connectionManager.sendKey(.prime)
            }
            RemoteButton(icon: "rectangle.on.rectangle", color: .gray, size: .medium) {
                connectionManager.sendKey(.source)
            }
        }
        .padding(20)
        .background(glassBackground)
    }

    private var floatingButtons: some View {
        VStack(spacing: 12) {
            Button {
                showTouchpad = true
            } label: {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 8)
            }
            Button {
                showKeyboard = true
            } label: {
                Image(systemName: "keyboard")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 8)
            }
        }
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - RemoteButton

enum RemoteButtonSize {
    case small, medium, large, navArrow
    var size: CGFloat {
        switch self { case .small: return 40; case .medium: return 50; case .large: return 60; case .navArrow: return 52 }
    }
}

struct RemoteButton: View {
    let icon: String
    let color: Color
    let size: RemoteButtonSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.size * 0.38, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size.size, height: size.size)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
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
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(color.opacity(0.3))
                .overlay(
                    Capsule().stroke(color.opacity(0.6), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
