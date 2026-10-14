import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 5591.0, in order.
    static func legacyInteractionSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5591.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyInteractionSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func legacyInteractionSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
