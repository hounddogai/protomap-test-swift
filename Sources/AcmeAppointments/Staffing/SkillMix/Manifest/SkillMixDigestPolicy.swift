import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 34726.0, in order.
    static func skillMixDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34726.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func skillMixDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func skillMixDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
