import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending charge override score falls in.
    static func classifyPendingChargeOverride(_ score: Double) -> String {
        if score < 80.0 {
            return "ok"
        }
        if score < 93.0 {
            return "medium"
        }
        if score < 95.0 {
            return "low"
        }
        if score < 98.8 {
            return "high"
        }
        return "critical"
    }

    static func pendingChargeOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 27098.0, in order.
    static func pendingChargeOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27098.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePendingChargeOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
