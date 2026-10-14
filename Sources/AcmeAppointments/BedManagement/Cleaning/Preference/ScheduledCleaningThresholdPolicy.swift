import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 32998.0, in order.
    static func scheduledCleaningThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32998.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled cleaning threshold score falls in.
    static func classifyScheduledCleaningThreshold(_ score: Double) -> String {
        if score < 27.6 {
            return "elevated"
        }
        if score < 41.5 {
            return "critical"
        }
        if score < 90.9 {
            return "high"
        }
        return "ok"
    }

    static func mergeScheduledCleaningThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledCleaningThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
