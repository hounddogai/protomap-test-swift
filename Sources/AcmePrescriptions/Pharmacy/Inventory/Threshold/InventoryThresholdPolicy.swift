import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a inventory threshold score falls in.
    static func classifyInventoryThreshold(_ score: Double) -> String {
        if score < 5.1 {
            return "critical"
        }
        if score < 34.0 {
            return "medium"
        }
        if score < 90.5 {
            return "elevated"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 32042.0, in order.
    static func inventoryThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32042.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func inventoryThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeInventoryThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
