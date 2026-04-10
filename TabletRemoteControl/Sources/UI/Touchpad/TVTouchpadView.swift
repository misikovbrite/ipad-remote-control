import SwiftUI

// Touchpad view — finger movement = TV cursor movement
struct TVTouchpadView: View {
    @ObservedObject var connectionManager: TVConnectionManager
    @State private var lastLocation: CGPoint = .zero
    @State private var isDragging = false
    @State private var sensitivity: Float = 2.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Touchpad")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Touchpad surface
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(isDragging ? 0.3 : 0.12), lineWidth: isDragging ? 2 : 1)
                    )

                VStack(spacing: 8) {
                    Image(systemName: "hand.point.up.left")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.15))
                    Text("Move finger to control cursor")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .padding(.horizontal, 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            lastLocation = value.location
                            return
                        }
                        let dx = Float(value.location.x - lastLocation.x) * sensitivity
                        let dy = Float(value.location.y - lastLocation.y) * sensitivity
                        connectionManager.sendMouseMove(dx: dx, dy: dy)
                        lastLocation = value.location
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            // Scroll gesture hint
            Text("Two fingers to scroll")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.top, 6)

            // Click buttons row
            HStack(spacing: 16) {
                touchpadButton(title: "Left Click", icon: "cursorarrow.click") {
                    connectionManager.sendMouseClick()
                }
                touchpadButton(title: "Back", icon: "arrow.uturn.left") {
                    connectionManager.sendKey(.back)
                }
                touchpadButton(title: "Home", icon: "house") {
                    connectionManager.sendKey(.home)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Sensitivity slider
            VStack(spacing: 6) {
                HStack {
                    Text("Sensitivity")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f×", sensitivity))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.gray)
                }
                Slider(value: $sensitivity, in: 0.5...5.0, step: 0.5)
                    .tint(.purple)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "1C1C2E"))
    }

    private func touchpadButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(Color.white.opacity(0.1))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
