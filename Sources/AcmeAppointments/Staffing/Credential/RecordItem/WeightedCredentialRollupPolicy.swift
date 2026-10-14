import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a weighted credential rollup score falls in.
    static func classifyWeightedCredentialRollup(_ score: Double) -> String {
        if score < 19.1 {
            return "minimal"
        }
        if score < 34.8 {
            return "elevated"
        }
        if score < 89.0 {
            return "watch"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 40879.0, in order.
    static func weightedCredentialRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40879.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedCredentialRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
