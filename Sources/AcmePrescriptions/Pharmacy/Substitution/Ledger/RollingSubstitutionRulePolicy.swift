import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeRollingSubstitutionRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a rolling substitution rule score falls in.
    static func classifyRollingSubstitutionRule(_ score: Double) -> String {
        if score < 74.9 {
            return "watch"
        }
        if score < 90.5 {
            return "ok"
        }
        return "minimal"
    }

    static func rollingSubstitutionRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 23095.0, in order.
    static func rollingSubstitutionRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23095.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
