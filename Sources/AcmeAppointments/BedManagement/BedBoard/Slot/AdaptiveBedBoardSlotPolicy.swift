import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 11725.0, in order.
    static func adaptiveBedBoardSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11725.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveBedBoardSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
