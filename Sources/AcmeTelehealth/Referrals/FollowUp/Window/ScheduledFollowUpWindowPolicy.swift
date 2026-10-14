import AcmePlatform
import Foundation

extension Referrals {
    static func scheduledFollowUpWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 64014.0, in order.
    static func scheduledFollowUpWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64014.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
