import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 51959.0, in order.
    static func tieredOvertimeProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51959.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredOvertimeProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
