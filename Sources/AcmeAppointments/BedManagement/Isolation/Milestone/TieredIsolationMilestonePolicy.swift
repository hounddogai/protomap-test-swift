import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a tiered isolation milestone code in its canonical TIM- form.
    static func normalizeTieredIsolationMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TIM-") {
            return clean
        }
        return "TIM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeTieredIsolationMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
