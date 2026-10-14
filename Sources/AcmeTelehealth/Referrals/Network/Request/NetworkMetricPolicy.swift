import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 2851.0, in order.
    static func networkMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2851.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func networkMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeNetworkMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a network metric score falls in.
    static func classifyNetworkMetric(_ score: Double) -> String {
        if score < 13.9 {
            return "elevated"
        }
        if score < 14.7 {
            return "critical"
        }
        if score < 29.1 {
            return "high"
        }
        if score < 75.2 {
            return "watch"
        }
        return "medium"
    }
}
