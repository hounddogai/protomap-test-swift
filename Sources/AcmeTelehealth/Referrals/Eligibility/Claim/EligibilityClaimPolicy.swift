import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a eligibility claim code in its canonical EC- form.
    static func normalizeEligibilityClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EC-") {
            return clean
        }
        return "EC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a eligibility claim score falls in.
    static func classifyEligibilityClaim(_ score: Double) -> String {
        if score < 37.6 {
            return "ok"
        }
        if score < 51.7 {
            return "medium"
        }
        if score < 85.9 {
            return "watch"
        }
        return "high"
    }
}
