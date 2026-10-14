import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a claim budget score falls in.
    static func classifyClaimBudget(_ score: Double) -> String {
        if score < 5.5 {
            return "ok"
        }
        if score < 5.7 {
            return "minimal"
        }
        if score < 84.2 {
            return "low"
        }
        if score < 84.3 {
            return "critical"
        }
        return "medium"
    }

    static func mergeClaimBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func claimBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
