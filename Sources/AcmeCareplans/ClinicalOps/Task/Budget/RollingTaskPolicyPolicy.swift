import AcmePlatform
import Foundation

extension ClinicalOps {
    static func rollingTaskPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 75006.0, in order.
    static func rollingTaskPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75006.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
