import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 75604.0, in order.
    static func pendingDenialPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75604.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingDenialPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
