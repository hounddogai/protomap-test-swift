import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a regional remittance rule score falls in.
    static func classifyRegionalRemittanceRule(_ score: Double) -> String {
        if score < 3.4 {
            return "minimal"
        }
        if score < 39.3 {
            return "critical"
        }
        if score < 44.8 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 44375.0, in order.
    static func regionalRemittanceRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44375.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRegionalRemittanceRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalRemittanceRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
