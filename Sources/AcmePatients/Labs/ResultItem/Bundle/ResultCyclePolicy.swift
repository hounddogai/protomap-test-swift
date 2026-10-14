import AcmePlatform
import Foundation

extension Labs {
    static func resultCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 82014.0, in order.
    static func resultCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82014.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
