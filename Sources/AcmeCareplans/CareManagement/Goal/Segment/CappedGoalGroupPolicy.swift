import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedGoalGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-goal-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedGoalGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a capped goal group score falls in.
    static func classifyCappedGoalGroup(_ score: Double) -> String {
        if score < 62.2 {
            return "high"
        }
        if score < 76.6 {
            return "medium"
        }
        return "minimal"
    }
}
