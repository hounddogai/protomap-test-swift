import AcmePlatform
import Foundation

extension ClinicalOps {
    static func globalRoundingScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 72154.0, in order.
    static func globalRoundingScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72154.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global rounding schedule score falls in.
    static func classifyGlobalRoundingSchedule(_ score: Double) -> String {
        if score < 3.0 {
            return "watch"
        }
        if score < 77.2 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeGlobalRoundingScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
