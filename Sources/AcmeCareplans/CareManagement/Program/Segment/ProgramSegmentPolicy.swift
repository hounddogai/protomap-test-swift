import AcmePlatform
import Foundation

extension CareManagement {
    static func programSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 87772.0, in order.
    static func programSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87772.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
