import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 52686.0, in order.
    static func weightedCourierDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52686.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedCourierDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
