import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up rule code in its canonical FUR- form.
    static func normalizeFollowUpRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUR-") {
            return clean
        }
        return "FUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFollowUpRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func followUpRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
