import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 18742.0, in order.
    static func eligibilityAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18742.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func eligibilityAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
