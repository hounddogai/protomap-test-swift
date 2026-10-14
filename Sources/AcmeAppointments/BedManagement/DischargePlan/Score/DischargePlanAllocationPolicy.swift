import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 6461.0, in order.
    static func dischargePlanAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6461.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func dischargePlanAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
