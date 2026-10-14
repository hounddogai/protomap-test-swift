import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 37986.0, in order.
    static func rollingReferenceRangeRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37986.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling reference range rollup score falls in.
    static func classifyRollingReferenceRangeRollup(_ score: Double) -> String {
        if score < 67.5 {
            return "critical"
        }
        if score < 69.3 {
            return "low"
        }
        if score < 71.3 {
            return "ok"
        }
        if score < 81.6 {
            return "high"
        }
        return "minimal"
    }
}
