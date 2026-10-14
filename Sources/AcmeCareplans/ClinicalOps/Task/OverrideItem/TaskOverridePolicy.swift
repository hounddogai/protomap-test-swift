import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeTaskOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a task override code in its canonical TO- form.
    static func normalizeTaskOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TO-") {
            return clean
        }
        return "TO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
