import AcmePlatform
import Foundation

extension Consent {
    static func mergeRegionalWitnessBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional witness budget score falls in.
    static func classifyRegionalWitnessBudget(_ score: Double) -> String {
        if score < 11.1 {
            return "critical"
        }
        if score < 29.4 {
            return "low"
        }
        if score < 50.5 {
            return "ok"
        }
        if score < 61.9 {
            return "medium"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 89490.0, in order.
    static func regionalWitnessBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89490.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
