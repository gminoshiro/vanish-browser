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
                VStack(spacing: 20) {
                    // Header - Trial ended message
                    if trialManager.isTrialExpired {
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("purchase.trialEndedHeading", comment: ""))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(NSLocalizedString("purchase.trialEndedSubheading", comment: ""))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30)
                        .padding(.horizontal, 24)
                    }

                    // Price Display - Large and prominent
                    VStack(spacing: 0) {
                        if let product = purchaseManager.products.first {
                            Text(product.displayPrice)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(.primary)
                        } else if purchaseManager.isLoading {
                            // Loading state
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.vertical, 20)
                        } else {
                            // Placeholder when no product loaded
                            Text("¥300")
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.top, trialManager.isTrialExpired ? 16 : 30)

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "lock.shield.fill", title: NSLocalizedString("purchase.feature.encryption", comment: ""))
                        FeatureRow(icon: "arrow.down.circle.fill", title: NSLocalizedString("purchase.feature.downloads", comment: ""))
                        FeatureRow(icon: "clock.fill", title: NSLocalizedString("purchase.feature.autoDelete", comment: ""))
                        FeatureRow(icon: "infinity", title: NSLocalizedString("purchase.feature.unlimited", comment: ""))
                    }
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    // Simple explanation
                    Text(NSLocalizedString("purchase.simpleExplanation", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)

                    // Product loading error state
                    if let error = purchaseManager.purchaseError {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text("商品情報の読み込みに失敗しました")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("再読み込み") {
                                Task {
                                    await purchaseManager.loadProducts()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 16)
                    }

                    Spacer(minLength: 20)

                    // CTA: Purchase Button - Large and prominent
                    Button(action: {
                        Task {
                            if purchaseManager.products.isEmpty {
                                await purchaseManager.loadProducts()
                            } else {
                                await purchaseProduct()
                            }
                        }
                    }) {
                        HStack {
                            if purchaseManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else if let product = purchaseManager.products.first {
                                Text("\(product.displayPrice)で今すぐ購入")
                                    .font(.title3.bold())
                            } else {
                                Text("¥300で今すぐ購入")
                                    .font(.title3.bold())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(purchaseManager.isLoading)
                    .padding(.horizontal, 24)

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
                    .padding(.top, 12)

                    // "Decide Later" option - small text link at bottom
                    if !trialManager.isTrialExpired {
                        Button(action: {
                            dismiss()
                        }) {
                            Text(NSLocalizedString("purchase.decideLater", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 32)
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
