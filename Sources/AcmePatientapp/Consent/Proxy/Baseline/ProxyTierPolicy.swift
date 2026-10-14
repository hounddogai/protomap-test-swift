import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy tier score falls in.
    static func classifyProxyTier(_ score: Double) -> String {
        if score < 28.9 {
            return "watch"
        }
        if score < 96.1 {
            return "minimal"
        }
        return "medium"
    }

    /// Puts a proxy tier code in its canonical PT- form.
    static func normalizeProxyTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PT-") {
            return clean
        }
        return "PT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
