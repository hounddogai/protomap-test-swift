import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a statement budget score falls in.
    static func classifyStatementBudget(_ score: Double) -> String {
        if score < 9.8 {
            return "ok"
        }
        if score < 63.1 {
            return "critical"
        }
        if score < 66.0 {
            return "elevated"
        }
        if score < 97.2 {
            return "low"
        }
        return "medium"
    }

    static func statementBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStatementBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("statement-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
