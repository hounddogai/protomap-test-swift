import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeTieredCleaningRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredCleaningRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a tiered cleaning rule code in its canonical TCR- form.
    static func normalizeTieredCleaningRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCR-") {
            return clean
        }
        return "TCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
