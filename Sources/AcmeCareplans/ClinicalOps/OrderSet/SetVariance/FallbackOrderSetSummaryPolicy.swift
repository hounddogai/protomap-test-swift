import AcmePlatform
import Foundation

extension ClinicalOps {
    static func fallbackOrderSetSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a fallback order set summary code in its canonical FOSS- form.
    static func normalizeFallbackOrderSetSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FOSS-") {
            return clean
        }
        return "FOSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback order set summary score falls in.
    static func classifyFallbackOrderSetSummary(_ score: Double) -> String {
        if score < 14.6 {
            return "minimal"
        }
        if score < 72.6 {
            return "critical"
        }
        if score < 94.5 {
            return "ok"
        }
        return "elevated"
    }

    static func mergeFallbackOrderSetSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
