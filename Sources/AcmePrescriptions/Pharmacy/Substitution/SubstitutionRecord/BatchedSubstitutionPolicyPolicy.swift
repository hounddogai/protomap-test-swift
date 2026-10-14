import AcmePlatform
import Foundation

extension Pharmacy {
    static func batchedSubstitutionPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched substitution policy score falls in.
    static func classifyBatchedSubstitutionPolicy(_ score: Double) -> String {
        if score < 37.9 {
            return "low"
        }
        if score < 76.7 {
            return "elevated"
        }
        return "watch"
    }

    static func batchedSubstitutionPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 15095.0, in order.
    static func batchedSubstitutionPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15095.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
