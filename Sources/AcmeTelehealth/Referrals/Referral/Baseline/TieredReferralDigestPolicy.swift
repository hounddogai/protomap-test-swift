import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a tiered referral digest score falls in.
    static func classifyTieredReferralDigest(_ score: Double) -> String {
        if score < 46.2 {
            return "watch"
        }
        if score < 70.9 {
            return "low"
        }
        if score < 93.2 {
            return "minimal"
        }
        return "elevated"
    }

    /// Puts a tiered referral digest code in its canonical TRD- form.
    static func normalizeTieredReferralDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRD-") {
            return clean
        }
        return "TRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
