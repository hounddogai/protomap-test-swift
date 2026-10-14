import AcmePlatform
import Foundation

extension Labs {
    static func rollingAccessionRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a rolling accession rollup code in its canonical RAR- form.
    static func normalizeRollingAccessionRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAR-") {
            return clean
        }
        return "RAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRollingAccessionRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a rolling accession rollup score falls in.
    static func classifyRollingAccessionRollup(_ score: Double) -> String {
        if score < 38.9 {
            return "ok"
        }
        if score < 93.4 {
            return "low"
        }
        if score < 97.5 {
            return "minimal"
        }
        return "critical"
    }
}
