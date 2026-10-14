import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredAuthorizationCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 15137.0, in order.
    static func tieredAuthorizationCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15137.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a tiered authorization cycle score falls in.
    static func classifyTieredAuthorizationCycle(_ score: Double) -> String {
        if score < 19.8 {
            return "elevated"
        }
        if score < 80.9 {
            return "medium"
        }
        return "high"
    }

    static func mergeTieredAuthorizationCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
