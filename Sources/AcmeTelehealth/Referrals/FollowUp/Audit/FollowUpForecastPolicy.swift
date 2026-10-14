import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up forecast code in its canonical FUF- form.
    static func normalizeFollowUpForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUF-") {
            return clean
        }
        return "FUF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFollowUpForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func followUpForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
