import AcmePlatform
import Foundation

extension Labs {
    static func mergeTieredPanelPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered panel plan score falls in.
    static func classifyTieredPanelPlan(_ score: Double) -> String {
        if score < 26.2 {
            return "medium"
        }
        if score < 42.1 {
            return "critical"
        }
        if score < 52.0 {
            return "low"
        }
        if score < 88.9 {
            return "elevated"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 59368.0, in order.
    static func tieredPanelPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59368.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
