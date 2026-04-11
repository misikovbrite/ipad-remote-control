import SwiftUI

struct AppsGridView: View {
    @EnvironmentObject var connectionManager: TVConnectionManager
    @State private var apps: [TVApp] = []
    @State private var isLoading = false

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 14)]

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView().tint(.indigo)
                    Text("Loading apps…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if apps.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(apps) { app in
                            AppTile(app: app) {
                                Task { try? await connectionManager.currentProtocol?.launchApp(app) }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task { await loadApps() }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Apps Available",
            systemImage: "apps.ipad",
            description: Text("App listing isn't supported for this TV model.")
        )
    }

    private func loadApps() async {
        isLoading = true
        apps = (try? await connectionManager.currentProtocol?.getApps()) ?? []
        isLoading = false
    }
}

// MARK: - App Tile

struct AppTile: View {
    let app: TVApp
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(appBackground(app.name))
                        .frame(width: 64, height: 64)
                        .shadow(color: appBackground(app.name).opacity(0.3), radius: 6, y: 3)
                    Image(systemName: appIcon(app.name))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(app.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func appIcon(_ name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("netflix"):   return "play.tv.fill"
        case let n where n.contains("youtube"):   return "play.rectangle.fill"
        case let n where n.contains("prime"):     return "video.fill"
        case let n where n.contains("spotify"):   return "music.note"
        case let n where n.contains("disney"):    return "sparkles.tv.fill"
        case let n where n.contains("apple tv"),
             let n where n.contains("appletv"):   return "appletv.fill"
        case let n where n.contains("hulu"):      return "play.circle.fill"
        case let n where n.contains("hbo"),
             let n where n.contains("max"):       return "film.fill"
        case let n where n.contains("twitch"):    return "gamecontroller.fill"
        case let n where n.contains("browser"),
             let n where n.contains("chrome"),
             let n where n.contains("opera"):     return "globe"
        default:                                   return "play.square.fill"
        }
    }

    private func appBackground(_ name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("netflix"):   return Color(hex: "E50914")
        case let n where n.contains("youtube"):   return Color(hex: "FF0000")
        case let n where n.contains("prime"):     return Color(hex: "00A8E0")
        case let n where n.contains("spotify"):   return Color(hex: "1DB954")
        case let n where n.contains("disney"):    return Color(hex: "113CCF")
        case let n where n.contains("apple tv"),
             let n where n.contains("appletv"):   return Color(hex: "333333")
        case let n where n.contains("hulu"):      return Color(hex: "1CE783")
        case let n where n.contains("hbo"),
             let n where n.contains("max"):       return Color(hex: "002BE7")
        case let n where n.contains("twitch"):    return Color(hex: "9146FF")
        default:                                   return Color.indigo
        }
    }
}
