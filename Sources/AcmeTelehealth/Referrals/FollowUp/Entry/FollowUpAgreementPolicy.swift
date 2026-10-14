import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up agreement code in its canonical FUA- form.
    static func normalizeFollowUpAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUA-") {
            return clean
        }
        return "FUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFollowUpAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
