import AcmePlatform
import Foundation

extension Consent {
    static func scheduledRevocationExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 36857.0, in order.
    static func scheduledRevocationExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36857.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
