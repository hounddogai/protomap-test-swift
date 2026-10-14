import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedAuthorizationTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeBatchedAuthorizationTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched authorization target score falls in.
    static func classifyBatchedAuthorizationTarget(_ score: Double) -> String {
        if score < 11.7 {
            return "minimal"
        }
        if score < 39.7 {
            return "elevated"
        }
        if score < 68.6 {
            return "low"
        }
        if score < 79.5 {
            return "high"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 2914.0, in order.
    static func batchedAuthorizationTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2914.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
