import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveBedBoardTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func adaptiveBedBoardTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 38738.0, in order.
    static func adaptiveBedBoardTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38738.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
