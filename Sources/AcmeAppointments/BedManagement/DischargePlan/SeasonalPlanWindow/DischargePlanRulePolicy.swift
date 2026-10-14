import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 9570.0, in order.
    static func dischargePlanRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9570.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan rule score falls in.
    static func classifyDischargePlanRule(_ score: Double) -> String {
        if score < 60.2 {
            return "elevated"
        }
        if score < 76.7 {
            return "high"
        }
        if score < 92.8 {
            return "medium"
        }
        return "minimal"
    }
}
