import AcmePlatform
import Foundation

extension Referrals {
    static func fallbackReferralReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func fallbackReferralReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a fallback referral reservation code in its canonical FRR- form.
    static func normalizeFallbackReferralReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRR-") {
            return clean
        }
        return "FRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback referral reservation score falls in.
    static func classifyFallbackReferralReservation(_ score: Double) -> String {
        if score < 26.8 {
            return "low"
        }
        if score < 52.3 {
            return "minimal"
        }
        if score < 74.5 {
            return "ok"
        }
        if score < 94.2 {
            return "medium"
        }
        return "high"
    }
}
