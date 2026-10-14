import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a regional order set override score falls in.
    static func classifyRegionalOrderSetOverride(_ score: Double) -> String {
        if score < 27.3 {
            return "high"
        }
        if score < 33.0 {
            return "medium"
        }
        if score < 33.5 {
            return "watch"
        }
        if score < 71.4 {
            return "ok"
        }
        return "elevated"
    }

    /// Puts a regional order set override code in its canonical ROSO- form.
    static func normalizeRegionalOrderSetOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROSO-") {
            return clean
        }
        return "ROSO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalOrderSetOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
