import AcmePlatform
import Foundation

extension Imaging {
    static func mergeStudyTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a study target score falls in.
    static func classifyStudyTarget(_ score: Double) -> String {
        if score < 20.4 {
            return "watch"
        }
        if score < 91.5 {
            return "elevated"
        }
        return "low"
    }

    static func studyTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 24390.0, in order.
    static func studyTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24390.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
