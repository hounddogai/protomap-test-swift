import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a seasonal risk score policy score falls in.
    static func classifySeasonalRiskScorePolicy(_ score: Double) -> String {
        if score < 17.1 {
            return "medium"
        }
        if score < 25.1 {
            return "watch"
        }
        if score < 49.5 {
            return "minimal"
        }
        if score < 73.9 {
            return "low"
        }
        return "ok"
    }

    /// Puts a seasonal risk score policy code in its canonical SRSP- form.
    static func normalizeSeasonalRiskScorePolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRSP-") {
            return clean
        }
        return "SRSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalRiskScorePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-risk-score-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
