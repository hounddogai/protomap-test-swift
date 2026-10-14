import AcmePlatform
import Foundation

extension Referrals {
    static func mergeManualNetworkForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual network forecast code in its canonical MNF- form.
    static func normalizeManualNetworkForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MNF-") {
            return clean
        }
        return "MNF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
