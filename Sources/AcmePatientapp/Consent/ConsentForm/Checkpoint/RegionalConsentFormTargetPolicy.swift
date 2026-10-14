import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 66883.0, in order.
    static func regionalConsentFormTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66883.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalConsentFormTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
