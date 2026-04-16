import Foundation

// MARK: - PremiumFeature

enum PremiumFeature {
    case keyboard
    case touchpad
    case appsGrid
    case multipleDevices
}

// MARK: - FeatureGate

struct FeatureGate {

    /// Returns true if the user can access the given feature.
    static func canAccess(_ feature: PremiumFeature, subscriptionService: SubscriptionService) -> Bool {
        switch feature {
        case .keyboard, .touchpad, .appsGrid, .multipleDevices:
            return subscriptionService.isPro
        }
    }
}
