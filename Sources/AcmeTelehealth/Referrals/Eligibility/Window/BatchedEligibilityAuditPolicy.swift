import AcmePlatform
import Foundation

extension Referrals {
    static func batchedEligibilityAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 26808.0, in order.
    static func batchedEligibilityAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26808.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched eligibility audit score falls in.
    static func classifyBatchedEligibilityAudit(_ score: Double) -> String {
        if score < 29.5 {
            return "low"
        }
        if score < 34.4 {
            return "elevated"
        }
        if score < 72.5 {
            return "high"
        }
        return "medium"
    }
}
