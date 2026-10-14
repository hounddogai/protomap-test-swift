import AcmePlatform
import Foundation

extension ClinicalOps {
    static func globalCareProtocolRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a global care protocol rule score falls in.
    static func classifyGlobalCareProtocolRule(_ score: Double) -> String {
        if score < 68.3 {
            return "watch"
        }
        if score < 86.1 {
            return "critical"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 70609.0, in order.
    static func globalCareProtocolRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70609.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
