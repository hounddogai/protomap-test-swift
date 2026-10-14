import AcmePlatform
import Foundation

extension Labs {
    static func manualPanelAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 99400.0, in order.
    static func manualPanelAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99400.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
