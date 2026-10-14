import AcmePlatform
import Foundation

extension Consent {
    static func mergeWeightedLanguageTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted language tier score falls in.
    static func classifyWeightedLanguageTier(_ score: Double) -> String {
        if score < 77.5 {
            return "critical"
        }
        if score < 99.8 {
            return "elevated"
        }
        return "low"
    }

    /// Puts a weighted language tier code in its canonical WLT- form.
    static func normalizeWeightedLanguageTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WLT-") {
            return clean
        }
        return "WLT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
