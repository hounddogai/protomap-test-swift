import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 24716.0, in order.
    static func goalTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24716.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a goal target score falls in.
    static func classifyGoalTarget(_ score: Double) -> String {
        if score < 11.1 {
            return "watch"
        }
        if score < 44.2 {
            return "high"
        }
        if score < 74.8 {
            return "elevated"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
