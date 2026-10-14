import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 65553.0, in order.
    static func acuityPlanEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65553.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func acuityPlanEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
