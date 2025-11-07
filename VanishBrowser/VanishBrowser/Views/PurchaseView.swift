//
//  PurchaseView.swift
//  VanishBrowser
//
//  Purchase modal for lifetime license
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var trialManager = TrialManager.shared

    @State private var showingRestoreAlert = false
    @State private var restoreSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon & Title
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.gradient)

                        Text(NSLocalizedString("purchase.title", comment: ""))
                            .font(.title.bold())
                            .multilineTextAlignment(.center)

                        Text(NSLocalizedString("purchase.subtitle", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)

                    // Trial Status
                    if trialManager.isTrialExpired {
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("purchase.trialExpired", comment: ""))
                                .font(.headline)
                                .foregroundColor(.red)

                            Text(NSLocalizedString("purchase.unlockFeatures", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "lock.shield.fill", title: NSLocalizedString("purchase.feature.encryption", comment: ""))
                        FeatureRow(icon: "arrow.down.circle.fill", title: NSLocalizedString("purchase.feature.downloads", comment: ""))
                        FeatureRow(icon: "clock.fill", title: NSLocalizedString("purchase.feature.autoDelete", comment: ""))
                        FeatureRow(icon: "infinity", title: NSLocalizedString("purchase.feature.unlimited", comment: ""))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Important Notice: Not a subscription
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(NSLocalizedString("purchase.important", comment: ""))
                                .font(.headline)
                        }

                        Text(NSLocalizedString("purchase.oneTimePayment", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Product & Price
                    if let product = purchaseManager.products.first {
                        VStack(spacing: 16) {
                            Text(product.displayName)
                                .font(.title2.bold())

                            Text(product.displayPrice)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.blue.gradient)

                            Text(NSLocalizedString("purchase.lifetimeAccess", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Purchase Button
                            Button(action: {
                                Task {
                                    await purchaseProduct()
                                }
                            }) {
                                HStack {
                                    if purchaseManager.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(NSLocalizedString("purchase.button", comment: ""))
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(purchaseManager.isLoading)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    } else {
                        if purchaseManager.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            Text(NSLocalizedString("purchase.loadingProducts", comment: ""))
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }

                    // Restore Purchases Button
                    Button(action: {
                        Task {
                            await restorePurchases()
                        }
                    }) {
                        Text(NSLocalizedString("purchase.restore", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(purchaseManager.isLoading)

                    // Terms & Privacy (optional)
                    HStack(spacing: 16) {
                        Button(NSLocalizedString("purchase.terms", comment: "")) {
                            // Open terms
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Button(NSLocalizedString("purchase.privacy", comment: "")) {
                            // Open privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !trialManager.isTrialExpired {
                        Button(NSLocalizedString("button.close", comment: "")) {
                            dismiss()
                        }
                    }
                }
            }
            .alert(NSLocalizedString("purchase.success", comment: ""), isPresented: $restoreSuccess) {
                Button(NSLocalizedString("button.ok", comment: "")) {
                    dismiss()
                }
            }
            .alert(NSLocalizedString("purchase.error", comment: ""), isPresented: $showingError) {
                Button(NSLocalizedString("button.ok", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .interactiveDismissDisabled(trialManager.isTrialExpired)
    }

    // MARK: - Purchase

    private func purchaseProduct() async {
        do {
            try await purchaseManager.purchase()
            trialManager.updateTrialStatus()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - Restore

    private func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
            trialManager.updateTrialStatus()
            restoreSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
                .frame(width: 32)

            Text(title)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    PurchaseView()
}
