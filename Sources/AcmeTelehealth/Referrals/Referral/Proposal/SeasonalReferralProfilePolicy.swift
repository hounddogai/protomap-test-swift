import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a seasonal referral profile score falls in.
    static func classifySeasonalReferralProfile(_ score: Double) -> String {
        if score < 14.7 {
            return "minimal"
        }
        if score < 77.0 {
            return "low"
        }
        return "elevated"
    }

    /// Puts a seasonal referral profile code in its canonical SRP- form.
    static func normalizeSeasonalReferralProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRP-") {
            return clean
        }
        return "SRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
