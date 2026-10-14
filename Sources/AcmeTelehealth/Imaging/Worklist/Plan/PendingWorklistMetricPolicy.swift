import AcmePlatform
import Foundation

extension Imaging {
    static func pendingWorklistMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 86605.0, in order.
    static func pendingWorklistMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 86605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
