import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeIsolationBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a isolation baseline score falls in.
    static func classifyIsolationBaseline(_ score: Double) -> String {
        if score < 23.6 {
            return "low"
        }
        if score < 31.5 {
            return "high"
        }
        if score < 56.8 {
            return "critical"
        }
        return "medium"
    }

    static func isolationBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 91327.0, in order.
    static func isolationBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91327.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
