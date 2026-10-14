import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a capped disclosure record score falls in.
    static func classifyCappedDisclosureRecord(_ score: Double) -> String {
        if score < 5.2 {
            return "high"
        }
        if score < 8.1 {
            return "ok"
        }
        if score < 84.7 {
            return "critical"
        }
        return "low"
    }

    /// Puts a capped disclosure record code in its canonical CDR- form.
    static func normalizeCappedDisclosureRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CDR-") {
            return clean
        }
        return "CDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
