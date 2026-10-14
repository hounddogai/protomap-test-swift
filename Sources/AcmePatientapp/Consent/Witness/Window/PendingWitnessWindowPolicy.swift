import AcmePlatform
import Foundation

extension Consent {
    static func pendingWitnessWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 92823.0, in order.
    static func pendingWitnessWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92823.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending witness window score falls in.
    static func classifyPendingWitnessWindow(_ score: Double) -> String {
        if score < 11.8 {
            return "low"
        }
        if score < 69.2 {
            return "critical"
        }
        return "high"
    }

    static func pendingWitnessWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
