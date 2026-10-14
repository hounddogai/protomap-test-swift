import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInventoryForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func inventoryForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a inventory forecast score falls in.
    static func classifyInventoryForecast(_ score: Double) -> String {
        if score < 18.0 {
            return "ok"
        }
        if score < 47.5 {
            return "low"
        }
        if score < 52.8 {
            return "critical"
        }
        if score < 91.9 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 2423.0, in order.
    static func inventoryForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2423.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
