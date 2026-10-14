import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 73647.0, in order.
    static func bedBoardBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73647.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func bedBoardBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
