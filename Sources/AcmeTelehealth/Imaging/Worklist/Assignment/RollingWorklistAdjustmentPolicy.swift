import AcmePlatform
import Foundation

extension Imaging {
    static func rollingWorklistAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 67978.0, in order.
    static func rollingWorklistAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67978.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
