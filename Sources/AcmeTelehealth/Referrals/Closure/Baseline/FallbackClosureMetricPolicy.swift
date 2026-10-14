import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 73545.0, in order.
    static func fallbackClosureMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73545.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackClosureMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a fallback closure metric score falls in.
    static func classifyFallbackClosureMetric(_ score: Double) -> String {
        if score < 13.1 {
            return "medium"
        }
        if score < 31.9 {
            return "elevated"
        }
        if score < 91.1 {
            return "low"
        }
        return "critical"
    }
}
