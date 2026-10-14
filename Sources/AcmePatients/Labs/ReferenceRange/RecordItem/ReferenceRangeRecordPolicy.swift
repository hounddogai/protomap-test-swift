import AcmePlatform
import Foundation

extension Labs {
    static func referenceRangeRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 83285.0, in order.
    static func referenceRangeRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83285.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func referenceRangeRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
