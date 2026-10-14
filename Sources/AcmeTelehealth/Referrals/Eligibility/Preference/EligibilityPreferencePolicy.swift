import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a eligibility preference code in its canonical EP- form.
    static func normalizeEligibilityPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EP-") {
            return clean
        }
        return "EP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilityPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
