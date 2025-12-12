//
//  TrialManager.swift
//  VanishBrowser
//
//  Created for trial period management
//

import Foundation
import Combine

class TrialManager: ObservableObject {
    static let shared = TrialManager()

    // Trial period: 7 days
    private static let trialPeriodDays = 7

    // Published states
    @Published var isTrialActive: Bool = false
    @Published var isTrialExpired: Bool = false
    @Published var trialDaysRemaining: Int = 0
    @Published var trialEndDate: Date?

    private let firstLaunchDateKey = "com.vanishbrowser.firstLaunchDate"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let hasShownTrialWelcomeKey = "hasShownTrialWelcome"

    private init() {
        migrateFromUserDefaults() // Migrate existing users
        setupTrialPeriod()
        updateTrialStatus()
    }

    // MARK: - Migration

    private func migrateFromUserDefaults() {
        // Migrate existing trial data from UserDefaults to Keychain
        if let oldDate = UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date,
           !KeychainHelper.shared.exists(forKey: firstLaunchDateKey) {
            _ = KeychainHelper.shared.save(oldDate, forKey: firstLaunchDateKey)
            UserDefaults.standard.removeObject(forKey: "firstLaunchDate")
            print("📦 Migrated trial data from UserDefaults to Keychain")
        }
    }

    // MARK: - Trial Setup

    private func setupTrialPeriod() {
        // Check if first launch date exists in Keychain
        if let existingDate = KeychainHelper.shared.getDate(forKey: firstLaunchDateKey) {
            print("📅 First launch date exists (Keychain): \(existingDate)")
            print("✅ Keychain persistence working - date survived app deletion!")
        } else {
            // First launch - record the date in Keychain
            let firstLaunch = Date()
            if KeychainHelper.shared.save(firstLaunch, forKey: firstLaunchDateKey) {
                print("🎉 First launch recorded (Keychain): \(firstLaunch)")
            } else {
                print("❌ Failed to save first launch date to Keychain")
            }
        }
    }

    // MARK: - Trial Status

    func updateTrialStatus() {
        guard let firstLaunchDate = KeychainHelper.shared.getDate(forKey: firstLaunchDateKey) else {
            // No first launch date - set as expired
            isTrialActive = false
            isTrialExpired = true
            trialDaysRemaining = 0
            return
        }

        // Check if user has purchased
        let hasPurchased = PurchaseManager.shared.isPurchased

        if hasPurchased {
            // User has purchased - no trial restrictions
            isTrialActive = false
            isTrialExpired = false
            trialDaysRemaining = 0
            return
        }

        // Calculate trial end date
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: Self.trialPeriodDays, to: firstLaunchDate) else {
            isTrialActive = false
            isTrialExpired = true
            trialDaysRemaining = 0
            return
        }

        self.trialEndDate = endDate
        let now = Date()

        if now < endDate {
            // Trial is active
            isTrialActive = true
            isTrialExpired = false

            let components = calendar.dateComponents([.day], from: now, to: endDate)
            trialDaysRemaining = max(0, (components.day ?? 0) + 1) // +1 to include current day

            print("✅ Trial active: \(trialDaysRemaining) days remaining")
        } else {
            // Trial expired
            isTrialActive = false
            isTrialExpired = true
            trialDaysRemaining = 0

            print("⏰ Trial expired")
        }
    }

    // MARK: - Feature Access

    func canAccessPremiumFeatures() -> Bool {
        // User can access features if:
        // 1. Trial is active, OR
        // 2. User has purchased
        return isTrialActive || PurchaseManager.shared.isPurchased
    }

    func shouldShowPaywall() -> Bool {
        // Show paywall if trial is expired and user hasn't purchased
        return isTrialExpired && !PurchaseManager.shared.isPurchased
    }

    // MARK: - Trial Info

    func getTrialStatusMessage() -> String {
        if PurchaseManager.shared.isPurchased {
            return NSLocalizedString("trial.purchased", comment: "")
        } else if isTrialActive {
            let format = NSLocalizedString("trial.daysRemaining", comment: "")
            return String(format: format, trialDaysRemaining)
        } else if isTrialExpired {
            return NSLocalizedString("trial.expired", comment: "")
        } else {
            return ""
        }
    }

    func getTrialEndDateString() -> String {
        guard let endDate = trialEndDate else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: endDate)
    }

    // MARK: - Welcome Alert

    func shouldShowTrialWelcome() -> Bool {
        // Show welcome alert if:
        // 1. User hasn't seen it yet
        // 2. Trial is active (not purchased)
        // 3. Not expired yet
        let hasShown = UserDefaults.standard.bool(forKey: hasShownTrialWelcomeKey)
        return !hasShown && isTrialActive && !PurchaseManager.shared.isPurchased
    }

    func markTrialWelcomeAsShown() {
        UserDefaults.standard.set(true, forKey: hasShownTrialWelcomeKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Reset (for testing only)

    #if DEBUG
    func resetTrial() {
        // Delete from Keychain
        _ = KeychainHelper.shared.delete(forKey: firstLaunchDateKey)

        // Delete from UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasLifetimeLicense")
        UserDefaults.standard.removeObject(forKey: hasShownTrialWelcomeKey)
        UserDefaults.standard.synchronize()

        setupTrialPeriod()
        updateTrialStatus()

        print("🔄 Trial reset for testing")
    }
    #endif
}
