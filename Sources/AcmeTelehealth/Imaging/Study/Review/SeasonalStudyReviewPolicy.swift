import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalStudyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 61513.0, in order.
    static func seasonalStudyReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61513.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
