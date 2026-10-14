import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 23591.0, in order.
    static func panelReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23591.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func panelReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
