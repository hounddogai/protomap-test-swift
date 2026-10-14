import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 81030.0, in order.
    static func networkReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81030.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a network review code in its canonical NR- form.
    static func normalizeNetworkReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NR-") {
            return clean
        }
        return "NR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func networkReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a network review score falls in.
    static func classifyNetworkReview(_ score: Double) -> String {
        if score < 2.5 {
            return "minimal"
        }
        if score < 23.8 {
            return "elevated"
        }
        if score < 29.0 {
            return "ok"
        }
        return "critical"
    }
}
