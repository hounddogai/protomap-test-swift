import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a rolling isolation preference score falls in.
    static func classifyRollingIsolationPreference(_ score: Double) -> String {
        if score < 12.5 {
            return "watch"
        }
        if score < 42.6 {
            return "critical"
        }
        if score < 91.8 {
            return "high"
        }
        if score < 95.2 {
            return "elevated"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 77500.0, in order.
    static func rollingIsolationPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77500.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingIsolationPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func rollingIsolationPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
