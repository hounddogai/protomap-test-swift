import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a strict risk score request score falls in.
    static func classifyStrictRiskScoreRequest(_ score: Double) -> String {
        if score < 15.5 {
            return "ok"
        }
        if score < 45.9 {
            return "critical"
        }
        if score < 71.9 {
            return "low"
        }
        if score < 75.7 {
            return "medium"
        }
        return "high"
    }

    /// Puts a strict risk score request code in its canonical SRSR- form.
    static func normalizeStrictRiskScoreRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRSR-") {
            return clean
        }
        return "SRSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictRiskScoreRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-risk-score-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
