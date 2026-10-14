import AcmePlatform
import Foundation

extension Referrals {
    static func cappedReferralAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a capped referral agreement code in its canonical CRA- form.
    static func normalizeCappedReferralAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRA-") {
            return clean
        }
        return "CRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedReferralAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
