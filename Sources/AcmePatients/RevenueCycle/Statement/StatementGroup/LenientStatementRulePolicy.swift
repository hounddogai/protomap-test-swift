import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeLenientStatementRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientStatementRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-statement-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientStatementRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a lenient statement rule score falls in.
    static func classifyLenientStatementRule(_ score: Double) -> String {
        if score < 4.0 {
            return "elevated"
        }
        if score < 56.9 {
            return "watch"
        }
        if score < 77.7 {
            return "high"
        }
        if score < 88.3 {
            return "low"
        }
        return "critical"
    }
}
