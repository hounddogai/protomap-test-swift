import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score forecast score falls in.
    static func classifyRiskScoreForecast(_ score: Double) -> String {
        if score < 35.6 {
            return "ok"
        }
        if score < 90.4 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
