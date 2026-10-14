import AcmePlatform
import Foundation

extension Referrals {
    static func mergeAdaptiveEligibilityForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive eligibility forecast code in its canonical AEF- form.
    static func normalizeAdaptiveEligibilityForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AEF-") {
            return clean
        }
        return "AEF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
