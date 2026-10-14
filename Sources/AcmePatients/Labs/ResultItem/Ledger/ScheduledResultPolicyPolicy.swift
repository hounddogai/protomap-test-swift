import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 80151.0, in order.
    static func scheduledResultPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80151.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled result policy score falls in.
    static func classifyScheduledResultPolicy(_ score: Double) -> String {
        if score < 35.5 {
            return "high"
        }
        if score < 44.0 {
            return "ok"
        }
        return "medium"
    }

    static func scheduledResultPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledResultPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-result-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
