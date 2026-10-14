import AcmePlatform
import Foundation

extension Referrals {
    static func mergeLegacyEligibilityBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy eligibility budget code in its canonical LEB- form.
    static func normalizeLegacyEligibilityBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LEB-") {
            return clean
        }
        return "LEB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
