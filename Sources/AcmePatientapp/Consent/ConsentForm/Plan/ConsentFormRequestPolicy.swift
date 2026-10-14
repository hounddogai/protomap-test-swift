import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 76091.0, in order.
    static func consentFormRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76091.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func consentFormRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func consentFormRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
