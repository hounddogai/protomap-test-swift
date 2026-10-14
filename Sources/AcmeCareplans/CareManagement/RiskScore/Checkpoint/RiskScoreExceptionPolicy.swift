import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreException() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a risk score exception score falls in.
    static func classifyRiskScoreException(_ score: Double) -> String {
        if score < 19.6 {
            return "high"
        }
        if score < 45.0 {
            return "watch"
        }
        if score < 93.0 {
            return "critical"
        }
        return "elevated"
    }
}
