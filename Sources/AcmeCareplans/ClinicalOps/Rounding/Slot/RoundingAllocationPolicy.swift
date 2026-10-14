import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding allocation score falls in.
    static func classifyRoundingAllocation(_ score: Double) -> String {
        if score < 4.9 {
            return "watch"
        }
        if score < 8.0 {
            return "high"
        }
        if score < 83.2 {
            return "ok"
        }
        return "minimal"
    }

    static func roundingAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a rounding allocation code in its canonical RA- form.
    static func normalizeRoundingAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRoundingAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
