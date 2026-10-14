import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score item code in its canonical RSI- form.
    static func normalizeRiskScoreItemCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSI-") {
            return clean
        }
        return "RSI-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a risk score item score falls in.
    static func classifyRiskScoreItem(_ score: Double) -> String {
        if score < 13.9 {
            return "watch"
        }
        if score < 20.8 {
            return "critical"
        }
        if score < 52.2 {
            return "high"
        }
        if score < 73.8 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreItem() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-item")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
