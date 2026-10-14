import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form digest score falls in.
    static func classifyConsentFormDigest(_ score: Double) -> String {
        if score < 11.8 {
            return "medium"
        }
        if score < 70.1 {
            return "elevated"
        }
        return "watch"
    }

    /// Puts a consent form digest code in its canonical CFD- form.
    static func normalizeConsentFormDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFD-") {
            return clean
        }
        return "CFD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
