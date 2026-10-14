import AcmePlatform
import Foundation

extension ClinicalOps {
    static func fallbackRoundingManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a fallback rounding manifest score falls in.
    static func classifyFallbackRoundingManifest(_ score: Double) -> String {
        if score < 18.1 {
            return "medium"
        }
        if score < 30.7 {
            return "elevated"
        }
        if score < 38.6 {
            return "critical"
        }
        if score < 44.3 {
            return "minimal"
        }
        return "high"
    }

    static func mergeFallbackRoundingManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback rounding manifest code in its canonical FRM- form.
    static func normalizeFallbackRoundingManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRM-") {
            return clean
        }
        return "FRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
