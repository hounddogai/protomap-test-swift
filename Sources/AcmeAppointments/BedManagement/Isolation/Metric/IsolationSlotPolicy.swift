import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 3201.0, in order.
    static func isolationSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3201.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func isolationSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
