import AcmePlatform
import Foundation

extension Pharmacy {
    static func substitutionWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeSubstitutionWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 23685.0, in order.
    static func substitutionWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23685.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a substitution window score falls in.
    static func classifySubstitutionWindow(_ score: Double) -> String {
        if score < 30.1 {
            return "watch"
        }
        if score < 41.9 {
            return "critical"
        }
        if score < 47.6 {
            return "low"
        }
        if score < 49.2 {
            return "elevated"
        }
        return "medium"
    }
}
