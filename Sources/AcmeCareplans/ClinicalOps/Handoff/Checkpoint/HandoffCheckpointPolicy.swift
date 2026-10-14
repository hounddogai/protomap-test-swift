import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 77462.0, in order.
    static func handoffCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77462.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
