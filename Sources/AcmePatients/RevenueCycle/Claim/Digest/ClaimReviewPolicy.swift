import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 11861.0, in order.
    static func claimReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11861.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func claimReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a claim review code in its canonical CR- form.
    static func normalizeClaimReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a claim review score falls in.
    static func classifyClaimReview(_ score: Double) -> String {
        if score < 12.7 {
            return "low"
        }
        if score < 63.3 {
            return "critical"
        }
        if score < 66.3 {
            return "medium"
        }
        if score < 91.4 {
            return "ok"
        }
        return "elevated"
    }
}
