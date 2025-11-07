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

    private let firstLaunchDateKey = "firstLaunchDate"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    private init() {
        setupTrialPeriod()
        updateTrialStatus()
    }

    // MARK: - Trial Setup

    private func setupTrialPeriod() {
        // Check if first launch date exists
        if let existingDate = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date {
            print("📅 First launch date exists: \(existingDate)")
        } else {
            // First launch - record the date
            let firstLaunch = Date()
            UserDefaults.standard.set(firstLaunch, forKey: firstLaunchDateKey)
            UserDefaults.standard.synchronize()
            print("🎉 First launch recorded: \(firstLaunch)")
        }
    }

    // MARK: - Trial Status

    func updateTrialStatus() {
        guard let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date else {
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

    // MARK: - Reset (for testing only)

    #if DEBUG
    func resetTrial() {
        UserDefaults.standard.removeObject(forKey: firstLaunchDateKey)
        UserDefaults.standard.removeObject(forKey: "hasLifetimeLicense")
        UserDefaults.standard.synchronize()

        setupTrialPeriod()
        updateTrialStatus()

        print("🔄 Trial reset for testing")
    }
    #endif
}
