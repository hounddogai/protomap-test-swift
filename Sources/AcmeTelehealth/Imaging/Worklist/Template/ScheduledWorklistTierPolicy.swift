import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a scheduled worklist tier score falls in.
    static func classifyScheduledWorklistTier(_ score: Double) -> String {
        if score < 61.1 {
            return "critical"
        }
        if score < 84.8 {
            return "watch"
        }
        return "high"
    }

    static func scheduledWorklistTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 41600.0, in order.
    static func scheduledWorklistTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41600.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledWorklistTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
