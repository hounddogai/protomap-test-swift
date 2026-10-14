import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a capped risk score window code in its canonical CRSW- form.
    static func normalizeCappedRiskScoreWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRSW-") {
            return clean
        }
        return "CRSW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped risk score window score falls in.
    static func classifyCappedRiskScoreWindow(_ score: Double) -> String {
        if score < 2.8 {
            return "ok"
        }
        if score < 5.1 {
            return "medium"
        }
        if score < 84.6 {
            return "elevated"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedRiskScoreWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-risk-score-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCappedRiskScoreWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
