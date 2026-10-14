import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeRollingCensusForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 980.0, in order.
    static func rollingCensusForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 980.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingCensusForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
