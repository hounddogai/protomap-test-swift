import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 16410.0, in order.
    static func worklistAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16410.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWorklistAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func worklistAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
