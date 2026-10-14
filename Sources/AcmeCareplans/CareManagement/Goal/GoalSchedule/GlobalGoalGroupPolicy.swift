import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalGoalGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-goal-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalGoalGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a global goal group score falls in.
    static func classifyGlobalGoalGroup(_ score: Double) -> String {
        if score < 34.3 {
            return "watch"
        }
        if score < 37.0 {
            return "high"
        }
        if score < 59.9 {
            return "low"
        }
        if score < 72.1 {
            return "elevated"
        }
        return "critical"
    }
}
