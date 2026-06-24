import Foundation
import RevenueCat

/// Wraps RevenueCat: entitlement state, current offering, purchase + restore.
/// Drives the paywall gate in RootView.
@MainActor
final class PurchaseManager: NSObject, ObservableObject {
    static let entitlementID = "premium"

    @Published var isSubscribed = false
    @Published var offering: Offering?
    @Published var isPurchasing = false
    @Published var isReady = false

    /// Drives the paywall cover over the app. Non-subscribers can dismiss it (the
    /// "X") into a limited experience; any paid action re-presents it.
    @Published var showPaywall = false

    /// Gate a paid action. Returns true if the user may proceed (subscribed);
    /// otherwise presents the paywall and returns false.
    @discardableResult
    func requireSubscription() -> Bool {
        if isSubscribed { return true }
        showPaywall = true
        return false
    }

    #if DEBUG
    // Dev bypass: launch with SIMCTL_CHILD_EDEN_PREMIUM=1 to skip the paywall.
    private let debugPremium = ProcessInfo.processInfo.environment["EDEN_PREMIUM"] == "1"
    #else
    private let debugPremium = false
    #endif

    override init() {
        super.init()
    }

    func start() async {
        Purchases.shared.delegate = self
        await loadOffering()
        await refresh()
        isReady = true
    }

    func refresh() async {
        if debugPremium { isSubscribed = true; return }
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        apply(info)
    }

    func loadOffering() async {
        offering = try? await Purchases.shared.offerings().current
    }

    func purchase(_ package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }
        guard let result = try? await Purchases.shared.purchase(package: package) else { return }
        apply(result.customerInfo)
    }

    func restore() async {
        guard let info = try? await Purchases.shared.restorePurchases() else { return }
        apply(info)
    }

    func apply(_ customerInfo: CustomerInfo) {
        if debugPremium {
            isSubscribed = true
            showPaywall = false
            return
        }
        isSubscribed = hasPremiumAccess(customerInfo)
        if isSubscribed { showPaywall = false }
    }

    private func hasPremiumAccess(_ customerInfo: CustomerInfo) -> Bool {
        let hasPremiumEntitlement = customerInfo.entitlements
            .activeInCurrentEnvironment
            .keys
            .contains(Self.entitlementID)
        let hasActiveSubscription = !customerInfo.activeSubscriptions.isEmpty
        return hasPremiumEntitlement || hasActiveSubscription
    }
}

extension PurchaseManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            self?.apply(customerInfo)
        }
    }
}
