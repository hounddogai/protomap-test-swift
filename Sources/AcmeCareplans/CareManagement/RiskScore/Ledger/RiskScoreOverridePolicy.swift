import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score override score falls in.
    static func classifyRiskScoreOverride(_ score: Double) -> String {
        if score < 1.5 {
            return "watch"
        }
        if score < 22.9 {
            return "elevated"
        }
        if score < 48.7 {
            return "ok"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRiskScoreOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a risk score override code in its canonical RSO- form.
    static func normalizeRiskScoreOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSO-") {
            return clean
        }
        return "RSO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
