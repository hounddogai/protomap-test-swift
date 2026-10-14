import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a adaptive follow up notice code in its canonical AFUN- form.
    static func normalizeAdaptiveFollowUpNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFUN-") {
            return clean
        }
        return "AFUN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAdaptiveFollowUpNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
