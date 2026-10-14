import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedRiskScoreManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-risk-score-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted risk score manifest score falls in.
    static func classifyWeightedRiskScoreManifest(_ score: Double) -> String {
        if score < 57.6 {
            return "low"
        }
        if score < 65.9 {
            return "high"
        }
        return "critical"
    }

    /// Puts a weighted risk score manifest code in its canonical WRSM- form.
    static func normalizeWeightedRiskScoreManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRSM-") {
            return clean
        }
        return "WRSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedRiskScoreManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
