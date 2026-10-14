import AcmePlatform
import Foundation

extension Referrals {
    static func referralEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a referral entry score falls in.
    static func classifyReferralEntry(_ score: Double) -> String {
        if score < 1.4 {
            return "critical"
        }
        if score < 31.3 {
            return "low"
        }
        if score < 82.3 {
            return "minimal"
        }
        return "elevated"
    }

    /// Puts a referral entry code in its canonical RE- form.
    static func normalizeReferralEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RE-") {
            return clean
        }
        return "RE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
