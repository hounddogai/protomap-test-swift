import AcmePlatform
import Foundation

extension Referrals {
    static func mergeLegacyReferralAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func legacyReferralAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a legacy referral assignment code in its canonical LRA- form.
    static func normalizeLegacyReferralAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRA-") {
            return clean
        }
        return "LRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy referral assignment score falls in.
    static func classifyLegacyReferralAssignment(_ score: Double) -> String {
        if score < 8.6 {
            return "ok"
        }
        if score < 94.7 {
            return "medium"
        }
        if score < 98.1 {
            return "watch"
        }
        return "high"
    }
}
