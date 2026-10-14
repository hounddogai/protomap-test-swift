import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a language profile score falls in.
    static func classifyLanguageProfile(_ score: Double) -> String {
        if score < 25.7 {
            return "medium"
        }
        if score < 25.8 {
            return "low"
        }
        return "critical"
    }

    /// Puts a language profile code in its canonical LP- form.
    static func normalizeLanguageProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LP-") {
            return clean
        }
        return "LP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLanguageProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
