import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 51576.0, in order.
    static func defaultGoalPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51576.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultGoalPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-goal-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default goal policy score falls in.
    static func classifyDefaultGoalPolicy(_ score: Double) -> String {
        if score < 10.0 {
            return "medium"
        }
        if score < 44.3 {
            return "minimal"
        }
        return "elevated"
    }

    static func defaultGoalPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
