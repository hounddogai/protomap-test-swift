import AcmePlatform
import Foundation

extension Consent {
    static func disclosureWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 80653.0, in order.
    static func disclosureWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80653.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
