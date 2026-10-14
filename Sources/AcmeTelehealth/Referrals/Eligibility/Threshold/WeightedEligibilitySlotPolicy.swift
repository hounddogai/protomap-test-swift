import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 19355.0, in order.
    static func weightedEligibilitySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19355.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedEligibilitySlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func weightedEligibilitySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
