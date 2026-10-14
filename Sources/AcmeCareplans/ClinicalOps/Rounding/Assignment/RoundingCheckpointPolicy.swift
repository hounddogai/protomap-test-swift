import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func mergeRoundingCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a rounding checkpoint code in its canonical RC- form.
    static func normalizeRoundingCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RC-") {
            return clean
        }
        return "RC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rounding checkpoint score falls in.
    static func classifyRoundingCheckpoint(_ score: Double) -> String {
        if score < 56.3 {
            return "medium"
        }
        if score < 69.7 {
            return "critical"
        }
        if score < 98.2 {
            return "elevated"
        }
        return "low"
    }
}
