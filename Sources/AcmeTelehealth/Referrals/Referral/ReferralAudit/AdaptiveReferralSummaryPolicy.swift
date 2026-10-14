import AcmePlatform
import Foundation

extension Referrals {
    static func mergeAdaptiveReferralSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive referral summary code in its canonical ARS- form.
    static func normalizeAdaptiveReferralSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARS-") {
            return clean
        }
        return "ARS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveReferralSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a adaptive referral summary score falls in.
    static func classifyAdaptiveReferralSummary(_ score: Double) -> String {
        if score < 23.8 {
            return "watch"
        }
        if score < 44.2 {
            return "critical"
        }
        if score < 61.8 {
            return "minimal"
        }
        return "elevated"
    }
}
