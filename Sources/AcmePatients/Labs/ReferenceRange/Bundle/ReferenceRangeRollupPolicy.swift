import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a reference range rollup score falls in.
    static func classifyReferenceRangeRollup(_ score: Double) -> String {
        if score < 19.5 {
            return "medium"
        }
        if score < 74.0 {
            return "elevated"
        }
        if score < 81.1 {
            return "watch"
        }
        return "ok"
    }

    static func referenceRangeRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 34524.0, in order.
    static func referenceRangeRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34524.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
