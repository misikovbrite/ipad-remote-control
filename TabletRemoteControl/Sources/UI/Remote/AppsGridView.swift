import SwiftUI

struct AppsGridView: View {
    @EnvironmentObject var connectionManager: TVConnectionManager
    @State private var apps: [TVApp] = []
    @State private var isLoading = false

    let columns = Array(repeating: GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 16), count: 4)

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.purple)
                    Text("Loading apps...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if apps.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
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
        .task { await loadApps() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "apps.ipad")
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.4))
            Text("No apps available")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("App listing is not supported\nfor this TV model")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private func loadApps() async {
        isLoading = true
        apps = (try? await connectionManager.currentProtocol?.getApps()) ?? []
        isLoading = false
    }
}

struct AppTile: View {
    let app: TVApp
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let iconURL = app.iconURL {
                    AsyncImage(url: iconURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "app.fill")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.purple)
                        .frame(width: 56, height: 56)
                }

                Text(app.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
            .background(Color.white.opacity(0.07))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
