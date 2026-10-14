import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 54167.0, in order.
    static func isolationClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54167.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeIsolationClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func isolationClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a isolation claim score falls in.
    static func classifyIsolationClaim(_ score: Double) -> String {
        if score < 4.6 {
            return "low"
        }
        if score < 43.3 {
            return "watch"
        }
        if score < 47.3 {
            return "elevated"
        }
        if score < 74.4 {
            return "medium"
        }
        return "high"
    }
}
