import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a interaction override score falls in.
    static func classifyInteractionOverride(_ score: Double) -> String {
        if score < 38.9 {
            return "watch"
        }
        if score < 53.4 {
            return "ok"
        }
        return "high"
    }

    static func mergeInteractionOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 40696.0, in order.
    static func interactionOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40696.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func interactionOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
