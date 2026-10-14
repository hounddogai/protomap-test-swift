import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network score score falls in.
    static func classifyNetworkScore(_ score: Double) -> String {
        if score < 6.4 {
            return "medium"
        }
        if score < 8.3 {
            return "critical"
        }
        if score < 47.9 {
            return "low"
        }
        if score < 72.1 {
            return "high"
        }
        return "minimal"
    }

    static func networkScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 57301.0, in order.
    static func networkScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57301.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeNetworkScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
