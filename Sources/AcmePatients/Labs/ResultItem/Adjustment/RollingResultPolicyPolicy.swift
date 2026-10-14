import AcmePlatform
import Foundation

extension Labs {
    static func rollingResultPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 91327.0, in order.
    static func rollingResultPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91327.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
