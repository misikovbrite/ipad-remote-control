import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    var subscriptionService: SubscriptionService
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = "yearly"
    @State private var showCloseButton = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Colors
    private let navyBg = Color(red: 0.039, green: 0.086, blue: 0.157)  // #0A1628
    private let indigoColor = Color.indigo
    private let indigo2 = Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6

    var body: some View {
        ZStack {
            // Background
            navyBg.ignoresSafeArea()

            // Radial accent gradient top center
            RadialGradient(
                colors: [indigoColor.opacity(0.20), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // [1] Title + Close button
                    titleBlock

                    // [2] Before/After banner
                    beforeAfterBanner
                        .padding(.top, 20)

                    // [3] Timeline
                    timelineSection
                        .padding(.top, 28)

                    // [4] Plan Cards
                    planCardsSection
                        .padding(.top, 24)

                    // [5] Trial info text
                    trialInfoText
                        .padding(.top, 12)

                    // [6] 14-day money-back guarantee
                    moneyBackGuarantee
                        .padding(.top, 14)

                    // Bottom spacer before features
                    Spacer(minLength: 120)

                    // [7] Features section
                    featuresSection
                        .padding(.top, 8)

                    // [8] Reviews carousel
                    reviewsSection
                        .padding(.top, 28)

                    // Bottom spacer before terms
                    Spacer(minLength: 120)

                    // [9] Terms & Privacy links
                    termsLinks
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomCTA
        }
        .interactiveDismissDisabled(!showCloseButton)
        .onChange(of: subscriptionService.isPro) { _, new in
            if new { dismiss(); onDismiss?() }
        }
        .task {
            await subscriptionService.loadProducts()
            // Delay close button
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showCloseButton = true }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - [1] Title Block

    private var titleBlock: some View {
        ZStack(alignment: .topTrailing) {
            Text("Control Your TV.\nNo Limits.")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.trailing, 24)

            if showCloseButton {
                Button {
                    dismiss()
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 22)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - [2] Before/After Banner

    private var beforeAfterBanner: some View {
        Image("before-after-banner")
            .resizable()
            .scaledToFill()
            .frame(height: 160)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 32)
    }

    // MARK: - [3] Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How Your Free Trial Works")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                timelineStep(
                    day: "Today",
                    icon: "sparkles",
                    title: "Instant access to all features",
                    isLast: false
                )
                timelineStep(
                    day: "Full Access",
                    icon: "lock.open.fill",
                    title: "Use keyboard, touchpad & apps grid",
                    isLast: false
                )
                timelineStep(
                    day: "Day 2",
                    icon: "bell.fill",
                    title: "We'll remind you before trial ends",
                    isLast: false
                )
                timelineStep(
                    day: "Day 3",
                    icon: "checkmark.circle.fill",
                    title: "Trial ends. Cancel anytime — no charge",
                    isLast: true
                )
            }
        }
        .padding(.horizontal, 32)
    }

    private func timelineStep(day: String, icon: String, title: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(indigoColor.opacity(0.25))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(indigoColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(indigoColor.opacity(0.25))
                        .frame(width: 2, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(indigoColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.top, 8)
        }
    }

    // MARK: - [4] Plan Cards

    private var planCardsSection: some View {
        HStack(spacing: 12) {
            planCard(
                id: "weekly",
                title: "Weekly",
                price: weeklyPriceString,
                period: "/week",
                subtitle: nil
            )
            planCard(
                id: "yearly",
                title: "Yearly",
                price: yearlyPriceString,
                period: "/year",
                subtitle: "3-day free trial"
            )
        }
        .frame(height: 90)
        .padding(.horizontal, 24)
    }

    private func planCard(id: String, title: String, price: String, period: String, subtitle: String?) -> some View {
        let isSelected = selectedPlan == id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPlan = id
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                        Text(period)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(indigoColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(indigoColor)
                        .padding(8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? indigoColor.opacity(0.12) : Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? indigoColor : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - [5] Trial info text

    private var trialInfoText: some View {
        Text(selectedPlan == "yearly"
             ? "Start your 3-day free trial. Cancel anytime before it ends."
             : "Billed weekly. Cancel anytime.")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }

    // MARK: - [6] Money-back guarantee

    private var moneyBackGuarantee: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 14))
                .foregroundColor(indigoColor)
            Text("14-day money-back guarantee")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(indigoColor.opacity(0.10))
        )
        .padding(.horizontal, 32)
    }

    // MARK: - [7] Features section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Everything Included")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                ForEach(features, id: \.title) { feature in
                    featureRow(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
                    if feature.title != features.last?.title {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(indigoColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(indigoColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - [8] Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What Users Say")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 12) {
                ForEach(reviews, id: \.author) { review in
                    reviewCard(review)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func reviewCard(_ review: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(starsString(5))
                    .font(.system(size: 12))
                Spacer()
                Text(review.author)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text(review.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func starsString(_ count: Int) -> AttributedString {
        var str = AttributedString(String(repeating: "★", count: count))
        str.foregroundColor = Color(red: 1, green: 0.8, blue: 0)
        return str
    }

    // MARK: - [9] Terms & Privacy

    private var termsLinks: some View {
        HStack(spacing: 4) {
            Link("Privacy Policy",
                 destination: URL(string: "https://britetodo.com/privacypolicy.php")!)
            Text("·")
            Link("Terms of Use",
                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.4))
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 4) {
            // Subscribe button
            Button {
                Task { await purchase() }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(selectedPlan == "yearly" ? "Start Free Trial" : "Subscribe Weekly")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [indigoColor, indigo2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .disabled(isPurchasing)

            // "No payment now" — opacity trick, NOT if/else
            Text("No payment now")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
                .opacity(selectedPlan == "yearly" ? 1 : 0)

            // Restore button
            Button {
                Task {
                    await subscriptionService.restore()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .background(navyBg.opacity(0.95))
    }

    // MARK: - Purchase action

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await subscriptionService.purchase(isYearly: selectedPlan == "yearly")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Price strings

    private var weeklyPriceString: String {
        subscriptionService.weeklyProduct?.displayPrice ?? "$5.99"
    }

    private var yearlyPriceString: String {
        subscriptionService.yearlyProduct?.displayPrice ?? "$19.99"
    }

    // MARK: - Data

    private struct FeatureItem {
        let icon: String
        let title: String
        let subtitle: String
    }

    private var features: [FeatureItem] {[
        FeatureItem(icon: "keyboard", title: "Keyboard Input", subtitle: "Type on your TV without a physical keyboard"),
        FeatureItem(icon: "hand.point.up.left.fill", title: "Touchpad Control", subtitle: "Use your iPad as a trackpad for your TV"),
        FeatureItem(icon: "square.grid.2x2", title: "Apps Grid", subtitle: "Browse and launch TV apps from your iPad"),
        FeatureItem(icon: "tv", title: "All TV Brands", subtitle: "Samsung, LG, Sony, Roku, Fire TV & more"),
        FeatureItem(icon: "rectangle.3.group", title: "Multiple Devices", subtitle: "Control all your TVs from one place"),
        FeatureItem(icon: "wifi", title: "Auto Discovery", subtitle: "Finds your TV automatically on Wi-Fi"),
        FeatureItem(icon: "play.circle", title: "Demo Mode", subtitle: "Try before you connect"),
    ]}

    private struct ReviewItem {
        let text: String
        let author: String
    }

    private var reviews: [ReviewItem] {[
        ReviewItem(text: "Finally replaced my remote!", author: "Alex M."),
        ReviewItem(text: "Works great with my Samsung", author: "Sarah K."),
        ReviewItem(text: "Keyboard feature is amazing", author: "James T."),
    ]}
}
