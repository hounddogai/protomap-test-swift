import AcmePlatform
import Foundation

extension Consent {
    static func seasonalDisclosureDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a seasonal disclosure digest code in its canonical SDD- form.
    static func normalizeSeasonalDisclosureDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDD-") {
            return clean
        }
        return "SDD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal disclosure digest score falls in.
    static func classifySeasonalDisclosureDigest(_ score: Double) -> String {
        if score < 67.8 {
            return "watch"
        }
        if score < 95.5 {
            return "medium"
        }
        return "elevated"
    }
}
