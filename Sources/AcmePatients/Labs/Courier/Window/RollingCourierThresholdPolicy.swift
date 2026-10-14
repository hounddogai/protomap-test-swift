import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 7548.0, in order.
    static func rollingCourierThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7548.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingCourierThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a rolling courier threshold score falls in.
    static func classifyRollingCourierThreshold(_ score: Double) -> String {
        if score < 20.5 {
            return "watch"
        }
        if score < 57.3 {
            return "medium"
        }
        if score < 84.4 {
            return "low"
        }
        return "elevated"
    }

    static func rollingCourierThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
