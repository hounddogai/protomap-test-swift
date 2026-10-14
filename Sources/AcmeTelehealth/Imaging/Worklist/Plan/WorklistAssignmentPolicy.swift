import AcmePlatform
import Foundation

extension Imaging {
    static func worklistAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 64795.0, in order.
    static func worklistAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64795.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
