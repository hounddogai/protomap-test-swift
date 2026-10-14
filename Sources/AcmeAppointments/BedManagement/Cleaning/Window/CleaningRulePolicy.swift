import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning rule score falls in.
    static func classifyCleaningRule(_ score: Double) -> String {
        if score < 32.5 {
            return "high"
        }
        if score < 44.2 {
            return "minimal"
        }
        if score < 65.3 {
            return "elevated"
        }
        return "ok"
    }

    static func cleaningRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 47101.0, in order.
    static func cleaningRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47101.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCleaningRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
