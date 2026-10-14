import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 10669.0, in order.
    static func dischargePlanRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10669.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan rollup score falls in.
    static func classifyDischargePlanRollup(_ score: Double) -> String {
        if score < 12.7 {
            return "elevated"
        }
        if score < 25.8 {
            return "high"
        }
        if score < 38.6 {
            return "medium"
        }
        if score < 45.3 {
            return "low"
        }
        return "watch"
    }

    static func dischargePlanRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func dischargePlanRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
