import AcmePlatform
import Foundation

extension Referrals {
    static func cappedClosureRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 61563.0, in order.
    static func cappedClosureRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61563.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
