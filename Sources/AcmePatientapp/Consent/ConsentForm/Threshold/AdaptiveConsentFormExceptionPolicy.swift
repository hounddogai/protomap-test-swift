import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveConsentFormExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func adaptiveConsentFormExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 34318.0, in order.
    static func adaptiveConsentFormExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34318.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
