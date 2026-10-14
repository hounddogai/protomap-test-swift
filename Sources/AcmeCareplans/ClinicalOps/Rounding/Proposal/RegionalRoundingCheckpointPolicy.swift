import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeRegionalRoundingCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalRoundingCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-rounding-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional rounding checkpoint code in its canonical RRC- form.
    static func normalizeRegionalRoundingCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRC-") {
            return clean
        }
        return "RRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional rounding checkpoint score falls in.
    static func classifyRegionalRoundingCheckpoint(_ score: Double) -> String {
        if score < 65.5 {
            return "high"
        }
        if score < 75.0 {
            return "critical"
        }
        if score < 81.8 {
            return "watch"
        }
        if score < 87.1 {
            return "low"
        }
        return "ok"
    }
}
