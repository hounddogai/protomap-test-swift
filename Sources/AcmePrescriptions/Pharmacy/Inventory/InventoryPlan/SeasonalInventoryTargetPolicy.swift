import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeSeasonalInventoryTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalInventoryTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a seasonal inventory target score falls in.
    static func classifySeasonalInventoryTarget(_ score: Double) -> String {
        if score < 4.9 {
            return "elevated"
        }
        if score < 53.3 {
            return "high"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 78903.0, in order.
    static func seasonalInventoryTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78903.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
