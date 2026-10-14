import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 32359.0, in order.
    static func rollingConsentFormSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32359.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingConsentFormSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
