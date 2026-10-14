import AcmePlatform
import Foundation

extension Referrals {
    static func mergeGlobalEligibilityPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global eligibility plan code in its canonical GEP- form.
    static func normalizeGlobalEligibilityPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GEP-") {
            return clean
        }
        return "GEP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
