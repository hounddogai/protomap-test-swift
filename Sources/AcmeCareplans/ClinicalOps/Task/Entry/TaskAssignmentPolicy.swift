import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a task assignment code in its canonical TA- form.
    static func normalizeTaskAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TA-") {
            return clean
        }
        return "TA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeTaskAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
