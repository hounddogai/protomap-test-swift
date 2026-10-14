import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 66960.0, in order.
    static func strictPriorityBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66960.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictPriorityBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
