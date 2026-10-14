import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 51640.0, in order.
    static func lenientProxyReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51640.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeLenientProxyReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient proxy review score falls in.
    static func classifyLenientProxyReview(_ score: Double) -> String {
        if score < 24.6 {
            return "critical"
        }
        if score < 45.0 {
            return "ok"
        }
        return "high"
    }

    static func lenientProxyReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
