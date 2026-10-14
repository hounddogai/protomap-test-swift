import AcmePlatform
import Foundation

extension Consent {
    static func rollingWitnessManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 94436.0, in order.
    static func rollingWitnessManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94436.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
