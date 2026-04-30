import Foundation
import OSLog
import Security

// MARK: - Entitlement Protocol

protocol EntitlementProvider: Sendable {
    var isPro: Bool { get async }
    func hasEntitlement(_ entitlement: Entitlement) async -> Bool
    func grantEntitlement(_ entitlement: Entitlement, source: EntitlementSource, transactionId: String?) async
    func revokeEntitlement(_ entitlement: Entitlement) async
    func refreshAll() async
}

// MARK: - Entitlement Types

enum Entitlement: String, CaseIterable, Codable {
    case ocr
    case autoScroll
    case iCloudSync
    case advancedExport
    case imageEditor

    static let proBundle: Set<Entitlement> = Set(Entitlement.allCases)
}

enum EntitlementSource: String, Codable {
    case appStoreIAP
    case applePay
    case stripe
    case wechatPay
    case alipay
    case paypal
    case promotional
    case restored
}

// MARK: - Entitlement Record

struct EntitlementRecord: Codable {
    let entitlement: Entitlement
    let source: EntitlementSource
    let grantedAt: Date
    let transactionId: String?
    var expiresAt: Date?
}

// MARK: - EntitlementManager

@MainActor
@Observable
final class EntitlementManager {
    static let shared = EntitlementManager()

    private(set) var activeEntitlements: Set<Entitlement> = []
    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "entitlement")
    private let persistence = EntitlementPersistence()

    var isPro: Bool {
        !self.activeEntitlements.isEmpty
    }

    private init() {
        self.loadPersistedEntitlements()
    }

    // MARK: - Public API

    func hasEntitlement(_ entitlement: Entitlement) -> Bool {
        self.activeEntitlements.contains(entitlement)
    }

    func grantPro(source: EntitlementSource, transactionId: String? = nil) {
        for entitlement in Entitlement.proBundle {
            self.grant(entitlement, source: source, transactionId: transactionId)
        }
        self.logger.info("Pro granted via \(source.rawValue), tx: \(transactionId ?? "nil")")
        AnalyticsManager.shared.track(.entitlementGranted(source: source.rawValue))
    }

    func grant(_ entitlement: Entitlement, source: EntitlementSource, transactionId: String? = nil) {
        self.activeEntitlements.insert(entitlement)

        let record = EntitlementRecord(
            entitlement: entitlement,
            source: source,
            grantedAt: Date(),
            transactionId: transactionId
        )
        self.persistence.save(record)
    }

    func revokePro() {
        self.activeEntitlements.removeAll()
        self.persistence.clearAll()
        self.logger.info("All entitlements revoked")
        AnalyticsManager.shared.track(.entitlementRevoked)
    }

    func revokeEntitlement(_ entitlement: Entitlement) {
        self.activeEntitlements.remove(entitlement)
        self.persistence.remove(entitlement)
    }

    /// Sync from StoreManager's IAP state
    func syncFromStoreKit(purchasedProductIDs: Set<String>) {
        if purchasedProductIDs.isEmpty {
            let iapEntitlements = self.persistence.records()
                .filter { $0.source == .appStoreIAP }
                .map(\.entitlement)
            for ent in iapEntitlements {
                self.activeEntitlements.remove(ent)
                self.persistence.remove(ent)
            }
        } else {
            self.grantPro(source: .appStoreIAP, transactionId: purchasedProductIDs.first)
        }
    }

    /// Called when third-party payment verification succeeds
    func onThirdPartyPaymentVerified(source: EntitlementSource, transactionId: String) {
        self.grantPro(source: source, transactionId: transactionId)
    }

    // MARK: - Persistence

    private func loadPersistedEntitlements() {
        let records = self.persistence.records()
        for record in records {
            if let expiresAt = record.expiresAt, expiresAt < Date() {
                self.persistence.remove(record.entitlement)
                continue
            }
            self.activeEntitlements.insert(record.entitlement)
        }
        if !self.activeEntitlements.isEmpty {
            self.logger.info("Loaded \(self.activeEntitlements.count) persisted entitlements")
        }
    }
}

// MARK: - Keychain-backed Persistence

private final class EntitlementPersistence: @unchecked Sendable {
    private let keychainKey = "com.scrollcap.entitlements"
    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "entitlement-store")

    func records() -> [EntitlementRecord] {
        guard let data = self.readKeychain() else { return [] }
        return (try? JSONDecoder().decode([EntitlementRecord].self, from: data)) ?? []
    }

    func save(_ record: EntitlementRecord) {
        var current = self.records().filter { $0.entitlement != record.entitlement }
        current.append(record)
        self.writeKeychain(current)
    }

    func remove(_ entitlement: Entitlement) {
        let updated = self.records().filter { $0.entitlement != entitlement }
        self.writeKeychain(updated)
    }

    func clearAll() {
        self.deleteKeychain()
    }

    // MARK: - Keychain Operations

    private func readKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func writeKeychain(_ records: [EntitlementRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }

        self.deleteKeychain()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            self.logger.error("Keychain write failed: \(status)")
        }
    }

    private func deleteKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.keychainKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
