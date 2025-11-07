//
//  PurchaseManager.swift
//  VanishBrowser
//
//  Created for IAP implementation
//

import Foundation
import StoreKit
import Combine

@MainActor
class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()

    // IAP Product ID
    static let lifetimeLicenseProductID = "com.vanishbrowser.fulllifetimelicense"

    // Published states
    @Published var isPurchased: Bool = false
    @Published var isLoading: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseError: String?

    private var updateListenerTask: Task<Void, Error>?

    private override init() {
        super.init()

        // Load purchase status from UserDefaults
        self.isPurchased = UserDefaults.standard.bool(forKey: "hasLifetimeLicense")

        // Start transaction listener
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.lifetimeLicenseProductID])
            self.products = products
            print("📦 Products loaded: \(products.count)")
        } catch {
            print("❌ Failed to load products: \(error)")
            self.purchaseError = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchase() async throws {
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update purchase status
                self.isPurchased = true
                UserDefaults.standard.set(true, forKey: "hasLifetimeLicense")
                UserDefaults.standard.synchronize()

                // Finish the transaction
                await transaction.finish()

                print("✅ Purchase successful!")

            case .userCancelled:
                print("⚠️ User cancelled purchase")

            case .pending:
                print("⏳ Purchase pending")

            @unknown default:
                break
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            self.purchaseError = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await updatePurchaseStatus()

            if isPurchased {
                print("✅ Purchase restored!")
            } else {
                throw PurchaseError.noPurchaseToRestore
            }
        } catch {
            print("❌ Restore failed: \(error)")
            self.purchaseError = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Update Purchase Status

    private func updatePurchaseStatus() async {
        var hasPurchase = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == Self.lifetimeLicenseProductID {
                    hasPurchase = true
                    break
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }

        self.isPurchased = hasPurchase
        UserDefaults.standard.set(hasPurchase, forKey: "hasLifetimeLicense")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }

                    await MainActor.run {
                        if transaction.productID == Self.lifetimeLicenseProductID {
                            self.isPurchased = true
                            UserDefaults.standard.set(true, forKey: "hasLifetimeLicense")
                            UserDefaults.standard.synchronize()
                        }
                    }

                    await transaction.finish()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case failedVerification
    case noPurchaseToRestore

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return NSLocalizedString("purchase.error.productNotFound", comment: "")
        case .failedVerification:
            return NSLocalizedString("purchase.error.failedVerification", comment: "")
        case .noPurchaseToRestore:
            return NSLocalizedString("purchase.error.noPurchaseToRestore", comment: "")
        }
    }
}
