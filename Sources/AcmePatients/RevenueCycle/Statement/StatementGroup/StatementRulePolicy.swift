import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func statementRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 36435.0, in order.
    static func statementRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36435.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a statement rule score falls in.
    static func classifyStatementRule(_ score: Double) -> String {
        if score < 33.0 {
            return "minimal"
        }
        if score < 54.3 {
            return "ok"
        }
        if score < 54.4 {
            return "watch"
        }
        return "high"
    }
}
