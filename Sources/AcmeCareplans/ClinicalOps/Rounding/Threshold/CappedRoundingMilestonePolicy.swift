import AcmePlatform
import Foundation

extension ClinicalOps {
    static func cappedRoundingMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeCappedRoundingMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped rounding milestone code in its canonical CRM- form.
    static func normalizeCappedRoundingMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRM-") {
            return clean
        }
        return "CRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
