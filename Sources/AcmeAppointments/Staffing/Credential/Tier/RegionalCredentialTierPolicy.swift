import AcmePlatform
import Foundation

extension Staffing {
    static func regionalCredentialTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func mergeRegionalCredentialTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a regional credential tier code in its canonical RCT- form.
    static func normalizeRegionalCredentialTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCT-") {
            return clean
        }
        return "RCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional credential tier score falls in.
    static func classifyRegionalCredentialTier(_ score: Double) -> String {
        if score < 2.9 {
            return "low"
        }
        if score < 48.6 {
            return "elevated"
        }
        if score < 54.4 {
            return "minimal"
        }
        if score < 99.0 {
            return "ok"
        }
        return "high"
    }
}
