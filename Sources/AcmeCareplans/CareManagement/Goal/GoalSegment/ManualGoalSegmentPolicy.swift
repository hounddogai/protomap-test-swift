import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual goal segment score falls in.
    static func classifyManualGoalSegment(_ score: Double) -> String {
        if score < 65.5 {
            return "critical"
        }
        if score < 71.0 {
            return "ok"
        }
        if score < 73.8 {
            return "low"
        }
        if score < 99.5 {
            return "watch"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualGoalSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-goal-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
