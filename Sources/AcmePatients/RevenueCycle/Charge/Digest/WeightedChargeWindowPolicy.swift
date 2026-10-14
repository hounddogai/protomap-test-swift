import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeWeightedChargeWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 57891.0, in order.
    static func weightedChargeWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57891.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted charge window score falls in.
    static func classifyWeightedChargeWindow(_ score: Double) -> String {
        if score < 89.6 {
            return "ok"
        }
        if score < 93.3 {
            return "watch"
        }
        if score < 94.0 {
            return "elevated"
        }
        return "critical"
    }
}
