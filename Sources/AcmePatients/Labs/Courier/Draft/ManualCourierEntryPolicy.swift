import AcmePlatform
import Foundation

extension Labs {
    static func manualCourierEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 51096.0, in order.
    static func manualCourierEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51096.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual courier entry score falls in.
    static func classifyManualCourierEntry(_ score: Double) -> String {
        if score < 21.2 {
            return "ok"
        }
        if score < 48.8 {
            return "high"
        }
        if score < 83.7 {
            return "watch"
        }
        if score < 92.1 {
            return "elevated"
        }
        return "low"
    }

    static func mergeManualCourierEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
