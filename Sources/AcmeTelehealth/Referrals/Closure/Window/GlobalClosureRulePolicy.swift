import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a global closure rule score falls in.
    static func classifyGlobalClosureRule(_ score: Double) -> String {
        if score < 18.5 {
            return "minimal"
        }
        if score < 34.0 {
            return "critical"
        }
        if score < 60.2 {
            return "medium"
        }
        return "watch"
    }

    static func mergeGlobalClosureRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalClosureRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-closure-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 53143.0, in order.
    static func globalClosureRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53143.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
