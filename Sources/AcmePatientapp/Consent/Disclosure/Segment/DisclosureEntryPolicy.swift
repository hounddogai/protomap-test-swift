import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a disclosure entry score falls in.
    static func classifyDisclosureEntry(_ score: Double) -> String {
        if score < 16.4 {
            return "high"
        }
        if score < 36.4 {
            return "ok"
        }
        if score < 37.5 {
            return "elevated"
        }
        if score < 62.9 {
            return "critical"
        }
        return "watch"
    }

    /// Puts a disclosure entry code in its canonical DE- form.
    static func normalizeDisclosureEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DE-") {
            return clean
        }
        return "DE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
