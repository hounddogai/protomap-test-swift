import AcmePlatform
import Foundation

extension Pharmacy {
    static func legacyRecallRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 92120.0, in order.
    static func legacyRecallRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92120.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyRecallRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
