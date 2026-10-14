import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure profile code in its canonical DP- form.
    static func normalizeDisclosureProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DP-") {
            return clean
        }
        return "DP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a disclosure profile score falls in.
    static func classifyDisclosureProfile(_ score: Double) -> String {
        if score < 24.1 {
            return "elevated"
        }
        if score < 71.1 {
            return "ok"
        }
        if score < 86.7 {
            return "watch"
        }
        if score < 95.6 {
            return "low"
        }
        return "minimal"
    }
}
