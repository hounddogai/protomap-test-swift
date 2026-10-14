import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a legacy care protocol digest code in its canonical LCPD- form.
    static func normalizeLegacyCareProtocolDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCPD-") {
            return clean
        }
        return "LCPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyCareProtocolDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a legacy care protocol digest score falls in.
    static func classifyLegacyCareProtocolDigest(_ score: Double) -> String {
        if score < 30.1 {
            return "watch"
        }
        if score < 41.3 {
            return "high"
        }
        if score < 54.2 {
            return "low"
        }
        if score < 79.6 {
            return "critical"
        }
        return "minimal"
    }
}
