import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    private let totalSteps = 11
    @State private var currentStep = 0

    // Quiz answers
    @State private var quizAnswer1: String? = nil
    @State private var quizAnswer2: String? = nil
    @State private var quizAnswer3: String? = nil
    @State private var selectedInterests: Set<String> = []

    // Animation states
    @State private var iconScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    @State private var card2Offset: CGFloat = 30
    @State private var card3Offset: CGFloat = 30
    @State private var card4Offset: CGFloat = 30

    // Floating orb animation states
    @State private var orb1Offset: CGFloat = 0
    @State private var orb2Offset: CGFloat = 0
    @State private var orb3Offset: CGFloat = 0

    let accent = Color(red: 0.15, green: 0.38, blue: 0.92)

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                switch currentStep {
                case 0:  step0_welcome
                case 1:  step1_anyTV
                case 2:  step2_autoDiscovery
                case 3:  step3_touchpad
                case 4:  step4_keyboard
                case 5:  step5_quiz1
                case 6:  step6_quiz2
                case 7:  step7_quiz3
                case 8:  step8_quiz4
                case 9:  step9_results
                case 10: step10_darkSetup
                default: EmptyView()
                }
            }
        }
        .onAppear {
            startOrbAnimations()
            triggerAnimations()
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.96, blue: 1.0),
                    Color(red: 0.88, green: 0.92, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating orbs
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.6, y: -60 + orb1Offset)

                Circle()
                    .fill(Color.cyan.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)
                    .offset(x: -40, y: geo.size.height * 0.35 + orb2Offset)

                Circle()
                    .fill(Color.indigo.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.65 + orb3Offset)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Animation Helpers

    private func resetAnimations() {
        iconScale = 0.5
        contentOpacity = 0
        cardOffset = 30
        card2Offset = 30
        card3Offset = 30
        card4Offset = 30
    }

    private func triggerAnimations() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.05)) {
            iconScale = 1.0
            contentOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15)) {
            cardOffset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.22)) {
            card2Offset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.29)) {
            card3Offset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.36)) {
            card4Offset = 0
        }
    }

    private func startOrbAnimations() {
        withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
            orb1Offset = 22
        }
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            orb2Offset = -18
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            orb3Offset = 16
        }
    }

    private func nextStep() {
        resetAnimations()
        withAnimation(.easeOut(duration: 0.15)) {
            currentStep += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            triggerAnimations()
        }
    }

    // MARK: - onboardingPage helper

    @ViewBuilder
    private func onboardingPage<Content: View>(
        showContinue: Bool = true,
        continueEnabled: Bool = true,
        continueLabel: String = "Continue",
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                content()
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 28)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
            }
            if showContinue {
                continueButton(label: continueLabel, enabled: continueEnabled)
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func continueButton(label: String = "Continue", enabled: Bool = true) -> some View {
        Button(action: nextStep) {
            Text(label)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(enabled ? accent : Color.gray.opacity(0.4))
                )
        }
        .disabled(!enabled)
        .opacity(contentOpacity)
    }

    // MARK: - Step 0: Welcome

    private var step0_welcome: some View {
        onboardingPage(continueLabel: "Get Started") {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(iconScale * 1.1)

                    Circle()
                        .fill(accent.opacity(0.06))
                        .frame(width: 110, height: 110)
                        .blur(radius: 8)
                        .scaleEffect(iconScale)

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent, Color(red: 0.08, green: 0.26, blue: 0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "tv.and.mediabox")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(color: accent.opacity(0.45), radius: 22, x: 0, y: 10)
                        .scaleEffect(iconScale)
                }

                VStack(spacing: 10) {
                    Text("Tablet Remote")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                    Text("Control")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                }
                .opacity(contentOpacity)

                Text("Turn your iPad into the ultimate smart TV remote")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.58))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(contentOpacity)

                Spacer().frame(height: 20)
            }
        }
    }

    // MARK: - Step 1: Works With Any TV

    private var step1_anyTV: some View {
        onboardingPage {
            VStack(spacing: 28) {
                featureIcon("tv.fill", color: accent)

                featureHeader(
                    title: "Works With Any TV",
                    subtitle: "Compatible with all major brands"
                )

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        smallFeatureCard(icon: "tv", label: "Samsung & LG", offset: cardOffset)
                        smallFeatureCard(icon: "tv", label: "Sony & Philips", offset: card2Offset)
                    }
                    HStack(spacing: 12) {
                        smallFeatureCard(icon: "flame.fill", label: "Roku & Fire TV", offset: card3Offset)
                        smallFeatureCard(icon: "appletv.fill", label: "Apple TV", offset: card4Offset)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Auto-Discovery

    private var step2_autoDiscovery: some View {
        onboardingPage {
            VStack(spacing: 28) {
                featureIcon("wifi", color: accent)

                featureHeader(
                    title: "Finds Your TV Automatically",
                    subtitle: "Just connect to the same Wi-Fi — your TV appears instantly"
                )

                VStack(spacing: 12) {
                    tripleCardRow(
                        cards: [
                            ("network", "Smart Scan", cardOffset),
                            ("checkmark.circle.fill", "Zero Setup", card2Offset),
                            ("bolt.fill", "Instant Connect", card3Offset)
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Step 3: Touchpad Control

    private var step3_touchpad: some View {
        onboardingPage {
            VStack(spacing: 28) {
                featureIcon("hand.point.up.left.fill", color: accent)

                featureHeader(
                    title: "Swipe to Control",
                    subtitle: "Use your iPad as a precision trackpad for your TV"
                )

                VStack(spacing: 12) {
                    tripleCardRow(
                        cards: [
                            ("cursorarrow", "Mouse Cursor", cardOffset),
                            ("hand.tap", "Scroll & Tap", card2Offset),
                            ("speedometer", "Adjustable Speed", card3Offset)
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Step 4: Smart Keyboard

    private var step4_keyboard: some View {
        onboardingPage {
            VStack(spacing: 28) {
                featureIcon("keyboard", color: accent)

                featureHeader(
                    title: "Type on Your TV",
                    subtitle: "Full keyboard for Netflix search, YouTube, and more"
                )

                VStack(spacing: 12) {
                    tripleCardRow(
                        cards: [
                            ("keyboard", "Full QWERTY", cardOffset),
                            ("text.bubble.fill", "Smart Autocomplete", card2Offset),
                            ("checkmark.seal.fill", "Works Everywhere", card3Offset)
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Step 5: Quiz 1 — TV Brand

    private var step5_quiz1: some View {
        onboardingPage(
            continueEnabled: quizAnswer1 != nil,
            continueLabel: "Continue"
        ) {
            VStack(spacing: 28) {
                quizHeader(
                    title: "Which TV brand do you have?",
                    subtitle: "We'll optimize the connection for your device"
                )

                let options: [(String, String)] = [
                    ("Samsung", "🟦"),
                    ("LG", "🔴"),
                    ("Sony", "⚪"),
                    ("Roku", "💜"),
                    ("Apple TV", ""),
                    ("Other", "⚙️")
                ]

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(options, id: \.0) { option in
                        quizSingleTile(
                            label: option.0,
                            emoji: option.1,
                            isSelected: quizAnswer1 == option.0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                quizAnswer1 = option.0
                            }
                        }
                        .offset(y: contentOpacity == 0 ? 30 : 0)
                        .opacity(contentOpacity)
                    }
                }
            }
        }
    }

    // MARK: - Step 6: Quiz 2 — What You Watch

    private var step6_quiz2: some View {
        onboardingPage(
            continueEnabled: quizAnswer2 != nil,
            continueLabel: "Continue"
        ) {
            VStack(spacing: 28) {
                quizHeader(
                    title: "What do you watch most?",
                    subtitle: "Helps us personalize your remote layout"
                )

                let options = [
                    "Netflix & Streaming",
                    "YouTube & Videos",
                    "Live TV & Sports",
                    "Gaming",
                    "Everything"
                ]

                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        quizSingleRowTile(
                            label: option,
                            isSelected: quizAnswer2 == option
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                quizAnswer2 = option
                            }
                        }
                    }
                }
                .offset(y: cardOffset)
                .opacity(contentOpacity)
            }
        }
    }

    // MARK: - Step 7: Quiz 3 — Remote Losing

    private var step7_quiz3: some View {
        onboardingPage(
            continueEnabled: quizAnswer3 != nil,
            continueLabel: "Continue"
        ) {
            VStack(spacing: 28) {
                quizHeader(
                    title: "How often do you lose your remote?",
                    subtitle: "Be honest — we won't judge 😄"
                )

                let options = [
                    "Every single day 😅",
                    "A few times a week",
                    "Rarely, I'm careful",
                    "I already lost it 🤷"
                ]

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(options, id: \.self) { option in
                        quizSingleTile(
                            label: option,
                            emoji: nil,
                            isSelected: quizAnswer3 == option
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                quizAnswer3 = option
                            }
                        }
                        .frame(height: 74)
                    }
                }
                .offset(y: cardOffset)
                .opacity(contentOpacity)
            }
        }
    }

    // MARK: - Step 8: Quiz 4 — Multi-select Interests

    private var step8_quiz4: some View {
        onboardingPage(
            continueEnabled: !selectedInterests.isEmpty,
            continueLabel: selectedInterests.isEmpty
                ? "Continue"
                : "Continue (\(selectedInterests.count) selected)"
        ) {
            VStack(spacing: 28) {
                quizHeader(
                    title: "What matters most?",
                    subtitle: "Select all that apply"
                )

                let options = [
                    "Instant Setup",
                    "Keyboard Control",
                    "Touchpad Mode",
                    "Multiple TVs",
                    "App Launcher",
                    "Volume Control"
                ]

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(options, id: \.self) { option in
                        quizMultiTile(
                            label: option,
                            isSelected: selectedInterests.contains(option)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedInterests.contains(option) {
                                    selectedInterests.remove(option)
                                } else {
                                    selectedInterests.insert(option)
                                }
                            }
                        }
                    }
                }
                .offset(y: cardOffset)
                .opacity(contentOpacity)
            }
        }
    }

    // MARK: - Step 9: Results

    private var step9_results: some View {
        onboardingPage(continueLabel: "Let's Go →") {
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .blur(radius: 16)
                        .scaleEffect(iconScale)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(iconScale)
                }

                VStack(spacing: 10) {
                    Text("Your Remote is Ready")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                        .multilineTextAlignment(.center)

                    Text("Personalized for \(quizAnswer1 ?? "your TV")")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.58))
                        .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)

                VStack(spacing: 12) {
                    resultCard(
                        icon: "bolt.fill",
                        title: "Instant Connection",
                        desc: "Optimized for \(quizAnswer1 ?? "your TV")",
                        offset: cardOffset
                    )
                    resultCard(
                        icon: "hand.point.up.left.fill",
                        title: "Touchpad Ready",
                        desc: "Precision cursor control",
                        offset: card2Offset
                    )
                    resultCard(
                        icon: "keyboard",
                        title: "Smart Keyboard",
                        desc: "Type on any app with ease",
                        offset: card3Offset
                    )
                }
            }
        }
    }

    // MARK: - Step 10: Dark Setup Screen

    private var step10_darkSetup: some View {
        DarkSetupScreen(accent: accent) {
            hasSeenOnboarding = true
            onComplete()
        }
    }

    // MARK: - Reusable Sub-views

    @ViewBuilder
    private func featureIcon(_ name: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 110, height: 110)
                .blur(radius: 14)
                .scaleEffect(iconScale)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: name)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: color.opacity(0.4), radius: 18, x: 0, y: 8)
                .scaleEffect(iconScale)
        }
    }

    @ViewBuilder
    private func featureHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.58))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .opacity(contentOpacity)
    }

    @ViewBuilder
    private func smallFeatureCard(icon: String, label: String, offset: CGFloat) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(accent)
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(contentOpacity)
    }

    @ViewBuilder
    private func tripleCardRow(cards: [(String, String, CGFloat)]) -> some View {
        HStack(spacing: 12) {
            ForEach(cards, id: \.1) { icon, label, offset in
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accent)
                    Text(label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.45))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .offset(y: offset)
                .opacity(contentOpacity)
            }
        }
    }

    @ViewBuilder
    private func quizHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.58))
                .multilineTextAlignment(.center)
        }
        .opacity(contentOpacity)
    }

    @ViewBuilder
    private func quizSingleTile(
        label: String,
        emoji: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let emoji = emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 22))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? accent : Color(red: 0.2, green: 0.27, blue: 0.45))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.08) : Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.04 : 0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func quizSingleRowTile(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? accent : Color(red: 0.2, green: 0.27, blue: 0.45))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accent)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.08) : Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func quizMultiTile(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accent)
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? accent : Color(red: 0.2, green: 0.27, blue: 0.45))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.08) : Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.04 : 0.06), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func resultCard(icon: String, title: String, desc: String, offset: CGFloat) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                Text(desc)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.47, blue: 0.62))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.80))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(contentOpacity)
    }
}

// MARK: - Dark Setup Screen

private struct DarkSetupScreen: View {
    let accent: Color
    let onComplete: () -> Void

    private let setupSteps = [
        "Detecting network...",
        "Scanning for TVs...",
        "Loading protocols...",
        "Ready!"
    ]

    @State private var completedSteps: Int = 0
    @State private var progressValue: CGFloat = 0
    @State private var showComplete = false
    @State private var stepOpacities: [Double] = [0, 0, 0, 0]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle orbs on dark bg
            GeometryReader { geo in
                Circle()
                    .fill(accent.opacity(0.07))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.55, y: 40)

                Circle()
                    .fill(Color.indigo.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: 20, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 36) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.15))
                            .frame(width: 96, height: 96)
                            .blur(radius: 16)

                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent, Color(red: 0.08, green: 0.26, blue: 0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "tv.and.mediabox")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: accent.opacity(0.5), radius: 20, x: 0, y: 8)
                    }

                    // Steps
                    VStack(spacing: 14) {
                        ForEach(0..<setupSteps.count, id: \.self) { i in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(i < completedSteps ? Color.green.opacity(0.2) : Color.white.opacity(0.07))
                                        .frame(width: 28, height: 28)
                                    if i < completedSteps {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.green)
                                    } else if i == completedSteps {
                                        Circle()
                                            .fill(accent.opacity(0.8))
                                            .frame(width: 10, height: 10)
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 8, height: 8)
                                    }
                                }

                                Text(setupSteps[i])
                                    .font(.system(size: 15, weight: i <= completedSteps ? .semibold : .regular, design: .rounded))
                                    .foregroundColor(
                                        i < completedSteps
                                            ? Color.green.opacity(0.9)
                                            : i == completedSteps
                                                ? Color.white
                                                : Color.white.opacity(0.3)
                                    )
                                Spacer()
                            }
                            .opacity(stepOpacities[i])
                            .frame(maxWidth: 400)
                        }
                    }

                    // Progress bar
                    VStack(spacing: 10) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [accent, Color.cyan.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progressValue, height: 6)
                            }
                        }
                        .frame(height: 6)
                        .frame(maxWidth: 400)

                        Text("\(Int(progressValue * 100))%")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    // Setup Complete
                    if showComplete {
                        Text("Setup Complete")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear {
            runSetupAnimation()
        }
    }

    private func runSetupAnimation() {
        // Show step labels first
        for i in 0..<setupSteps.count {
            withAnimation(.easeIn(duration: 0.3).delay(Double(i) * 0.1)) {
                stepOpacities[i] = 1.0
            }
        }

        // Animate through each step
        for i in 0..<setupSteps.count {
            let delay = 0.4 + Double(i) * 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    completedSteps = i + 1
                    progressValue = CGFloat(i + 1) / CGFloat(setupSteps.count)
                }
            }
        }

        // Show "Setup Complete"
        let completeDelay = 0.4 + Double(setupSteps.count) * 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + completeDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showComplete = true
            }
        }

        // Call onComplete
        DispatchQueue.main.asyncAfter(deadline: .now() + completeDelay + 0.8) {
            onComplete()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    OnboardingView {
        print("Onboarding complete")
    }
}
#endif
