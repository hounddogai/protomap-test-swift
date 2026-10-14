import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a seasonal care protocol policy score falls in.
    static func classifySeasonalCareProtocolPolicy(_ score: Double) -> String {
        if score < 41.7 {
            return "critical"
        }
        if score < 52.6 {
            return "watch"
        }
        return "elevated"
    }

    static func seasonalCareProtocolPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 95532.0, in order.
    static func seasonalCareProtocolPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95532.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func seasonalCareProtocolPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
