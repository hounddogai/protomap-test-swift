import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a fallback referral variance code in its canonical FRV- form.
    static func normalizeFallbackReferralVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRV-") {
            return clean
        }
        return "FRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackReferralVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a fallback referral variance score falls in.
    static func classifyFallbackReferralVariance(_ score: Double) -> String {
        if score < 13.1 {
            return "critical"
        }
        if score < 72.8 {
            return "elevated"
        }
        return "high"
    }
}
