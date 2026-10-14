import AcmePlatform
import Foundation

extension CareManagement {
    static func pendingRiskScoreRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingRiskScoreRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-risk-score-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending risk score rollup score falls in.
    static func classifyPendingRiskScoreRollup(_ score: Double) -> String {
        if score < 45.7 {
            return "low"
        }
        if score < 77.1 {
            return "medium"
        }
        if score < 81.0 {
            return "ok"
        }
        if score < 96.6 {
            return "critical"
        }
        return "elevated"
    }
}
