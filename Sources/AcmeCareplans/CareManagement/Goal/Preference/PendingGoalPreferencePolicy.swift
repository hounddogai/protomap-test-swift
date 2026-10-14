import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending goal preference score falls in.
    static func classifyPendingGoalPreference(_ score: Double) -> String {
        if score < 9.9 {
            return "medium"
        }
        if score < 61.1 {
            return "minimal"
        }
        return "ok"
    }

    static func pendingGoalPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingGoalPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-goal-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
