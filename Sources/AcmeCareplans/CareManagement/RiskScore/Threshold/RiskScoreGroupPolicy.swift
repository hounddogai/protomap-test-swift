import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score group score falls in.
    static func classifyRiskScoreGroup(_ score: Double) -> String {
        if score < 19.5 {
            return "critical"
        }
        if score < 37.4 {
            return "watch"
        }
        if score < 45.7 {
            return "elevated"
        }
        if score < 60.4 {
            return "minimal"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
