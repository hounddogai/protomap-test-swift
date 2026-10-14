import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict proxy preference code in its canonical SPP- form.
    static func normalizeStrictProxyPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPP-") {
            return clean
        }
        return "SPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict proxy preference score falls in.
    static func classifyStrictProxyPreference(_ score: Double) -> String {
        if score < 50.1 {
            return "watch"
        }
        if score < 52.8 {
            return "critical"
        }
        if score < 78.9 {
            return "high"
        }
        return "low"
    }
}
