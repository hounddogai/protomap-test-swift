import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning cycle score falls in.
    static func classifyCleaningCycle(_ score: Double) -> String {
        if score < 42.4 {
            return "medium"
        }
        if score < 66.8 {
            return "minimal"
        }
        if score < 94.9 {
            return "ok"
        }
        return "high"
    }

    static func mergeCleaningCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 50061.0, in order.
    static func cleaningCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50061.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cleaningCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
