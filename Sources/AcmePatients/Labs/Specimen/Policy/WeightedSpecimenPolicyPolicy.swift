import AcmePlatform
import Foundation

extension Labs {
    static func weightedSpecimenPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 40019.0, in order.
    static func weightedSpecimenPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40019.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
