import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a isolation forecast score falls in.
    static func classifyIsolationForecast(_ score: Double) -> String {
        if score < 25.0 {
            return "minimal"
        }
        if score < 39.9 {
            return "elevated"
        }
        if score < 86.4 {
            return "critical"
        }
        return "ok"
    }

    static func mergeIsolationForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 14530.0, in order.
    static func isolationForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14530.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
