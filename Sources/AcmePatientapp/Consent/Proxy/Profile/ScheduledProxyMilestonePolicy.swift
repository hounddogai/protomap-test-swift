import AcmePlatform
import Foundation

extension Consent {
    /// Puts a scheduled proxy milestone code in its canonical SPM- form.
    static func normalizeScheduledProxyMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPM-") {
            return clean
        }
        return "SPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledProxyMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
