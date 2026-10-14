import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a seasonal credential tier code in its canonical SCT- form.
    static func normalizeSeasonalCredentialTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCT-") {
            return clean
        }
        return "SCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal credential tier score falls in.
    static func classifySeasonalCredentialTier(_ score: Double) -> String {
        if score < 22.3 {
            return "high"
        }
        if score < 23.7 {
            return "ok"
        }
        if score < 79.5 {
            return "critical"
        }
        return "elevated"
    }

    static func mergeSeasonalCredentialTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
