import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a global goal assignment score falls in.
    static func classifyGlobalGoalAssignment(_ score: Double) -> String {
        if score < 12.4 {
            return "low"
        }
        if score < 61.3 {
            return "high"
        }
        if score < 86.2 {
            return "critical"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalGoalAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-goal-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
