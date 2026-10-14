import AcmePlatform
import Foundation

extension Referrals {
    static func mergeClosurePreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 71981.0, in order.
    static func closurePreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71981.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func closurePreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
