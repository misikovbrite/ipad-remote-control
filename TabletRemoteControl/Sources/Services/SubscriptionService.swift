import StoreKit
import Foundation

// MARK: - ProState

enum ProState: String, Codable {
    case notPurchased
    case active
    case inGrace
    case billingRetry
    case expired

    var hasAccess: Bool {
        self == .active || self == .inGrace || self == .billingRetry
    }
}

// MARK: - SubscriptionService

@Observable
class SubscriptionService {

    static let shared = SubscriptionService()

    // MARK: Published state

    var proState: ProState = .notPurchased {
        didSet { cacheProState(proState) }
    }
    var isPro: Bool { proState.hasAccess }

    var weeklyProduct: Product?
    var yearlyProduct: Product?
    var isLoading = false
    var errorMessage: String?

    // MARK: Private

    private let weeklyID  = "ipadremotecontrolapp_weekly"
    private let yearlyID  = "ipadremotecontrolapp_yearly"
    private let cacheKey  = "pro_state_v1"
    private var updatesTask: Task<Void, Never>?

    // MARK: Init

    private init() {
        // Restore cached state for offline access
        if let raw = UserDefaults.standard.string(forKey: cacheKey),
           let cached = ProState(rawValue: raw) {
            proState = cached
        }
        listenForUpdates()
    }

    // MARK: - Load Products

    func loadProducts() async {
        guard weeklyProduct == nil || yearlyProduct == nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            let products = try await Product.products(for: [weeklyID, yearlyID])
            for product in products {
                if product.id == weeklyID  { weeklyProduct  = product }
                if product.id == yearlyID  { yearlyProduct  = product }
            }
        } catch {
            errorMessage = "Could not load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(isYearly: Bool) async throws {
        guard let product = isYearly ? yearlyProduct : weeklyProduct else {
            throw SubscriptionError.productNotLoaded
        }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateProState(for: transaction)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        var foundActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == weeklyID || transaction.productID == yearlyID {
                    await updateProState(for: transaction)
                    foundActive = true
                    await transaction.finish()
                    break
                }
            }
        }
        if !foundActive {
            proState = .notPurchased
        }
    }

    // MARK: - Listen For Updates

    func listenForUpdates() {
        updatesTask?.cancel()
        updatesTask = Task(priority: .background) {
            for await result in Transaction.updates {
                if let transaction = try? checkVerified(result) {
                    await updateProState(for: transaction)
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private func updateProState(for transaction: Transaction) async {
        // Check if subscription is still active
        if transaction.revocationDate != nil {
            proState = .expired
            return
        }

        // For auto-renewable subscriptions, check renewal status
        if let expirationDate = transaction.expirationDate {
            if expirationDate > Date() {
                // Look up renewal info for detailed state
                proState = await resolveActiveState(productID: transaction.productID)
            } else {
                proState = .expired
            }
        } else {
            proState = .active
        }
    }

    private func resolveActiveState(productID: String) async -> ProState {
        // Check subscription statuses for grace period / billing retry
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: "remote_premium")
            for status in statuses {
                guard (try? status.renewalInfo.payloadValue) != nil else { continue }
                switch status.state {
                case .subscribed:
                    return .active
                case .inGracePeriod:
                    return .inGrace
                case .inBillingRetryPeriod:
                    return .billingRetry
                case .expired, .revoked:
                    return .expired
                default:
                    return .active
                }
            }
        } catch {
            // Fallback to active if we can't determine
        }
        return .active
    }

    private func cacheProState(_ state: ProState) {
        UserDefaults.standard.set(state.rawValue, forKey: cacheKey)
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productNotLoaded
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .productNotLoaded:   return "Product information not available. Please try again."
        case .failedVerification: return "Purchase verification failed."
        }
    }
}
