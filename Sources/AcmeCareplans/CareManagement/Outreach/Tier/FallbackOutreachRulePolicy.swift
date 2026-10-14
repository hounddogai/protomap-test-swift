import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackOutreachRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-outreach-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackOutreachRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 92955.0, in order.
    static func fallbackOutreachRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92955.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackOutreachRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
