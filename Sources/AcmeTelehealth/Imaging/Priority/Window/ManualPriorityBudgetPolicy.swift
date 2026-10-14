import AcmePlatform
import Foundation

extension Imaging {
    static func mergeManualPriorityBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 95150.0, in order.
    static func manualPriorityBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95150.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualPriorityBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a manual priority budget score falls in.
    static func classifyManualPriorityBudget(_ score: Double) -> String {
        if score < 11.7 {
            return "high"
        }
        if score < 65.8 {
            return "medium"
        }
        if score < 70.4 {
            return "critical"
        }
        if score < 74.3 {
            return "low"
        }
        return "minimal"
    }
}
