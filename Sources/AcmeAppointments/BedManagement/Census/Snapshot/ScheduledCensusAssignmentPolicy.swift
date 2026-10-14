import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeScheduledCensusAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a scheduled census assignment code in its canonical SCA- form.
    static func normalizeScheduledCensusAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCA-") {
            return clean
        }
        return "SCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
