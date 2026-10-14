import AcmePlatform
import Foundation

extension Consent {
    static func mergeRollingDisclosureBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 5416.0, in order.
    static func rollingDisclosureBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5416.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling disclosure budget score falls in.
    static func classifyRollingDisclosureBudget(_ score: Double) -> String {
        if score < 22.9 {
            return "ok"
        }
        if score < 33.0 {
            return "low"
        }
        if score < 53.5 {
            return "minimal"
        }
        if score < 67.3 {
            return "high"
        }
        return "critical"
    }
}
