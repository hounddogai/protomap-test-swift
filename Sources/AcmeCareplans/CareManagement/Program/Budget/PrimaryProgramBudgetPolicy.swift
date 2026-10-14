import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryProgramBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 68419.0, in order.
    static func primaryProgramBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68419.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryProgramBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
