import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 34960.0, in order.
    static func defaultDisclosureSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34960.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultDisclosureSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
