import StoreKit
import Observation

/// The one-time "Sprout Pro" unlock, using StoreKit 2.
///
/// Runs from Xcode use `Sprout.storekit` (see the scheme in project.yml), so purchases work in
/// the simulator and on device without App Store Connect.
///
/// Gate Pro features where they're used, not by deleting state: read `store.isPro`, fall back to the
/// free behaviour when it's false, and have locked controls open `PaywallView` instead of acting.
@MainActor @Observable
final class Store {
    nonisolated static let proID = "com.brendanchamberlain.sprout.pro"

    private(set) var product: Product?
    private(set) var isPro: Bool
    private(set) var isLoading = true
    private(set) var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        // Start from the last known state so Pro features don't flicker off while StoreKit checks.
        isPro = UserDefaults.standard.bool(forKey: "isPro")
        #if DEBUG
        // Screenshot mode: `-demoPro YES` unlocks Pro without a purchase.
        if UserDefaults.standard.bool(forKey: "demoPro") { isPro = true }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await load() }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        product = try? await Product.products(for: [Self.proID]).first
        await refreshEntitlements()
    }

    func purchase() async {
        if product == nil { await load() }
        guard let product else {
            errorMessage = "Couldn't reach the App Store. Check your connection and try again."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .pending:
                errorMessage = "Your purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshEntitlements()
        if !isPro && errorMessage == nil {
            errorMessage = "No previous Pro purchase was found for this Apple Account."
        }
    }

    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setPro(owned)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.proID {
            setPro(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setPro(_ value: Bool) {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "demoPro") {
            isPro = true
            return
        }
        #endif
        isPro = value
        UserDefaults.standard.set(value, forKey: "isPro")
    }
}
