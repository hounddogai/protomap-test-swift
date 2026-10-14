import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a scheduled cleaning claim code in its canonical SCC- form.
    static func normalizeScheduledCleaningClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCC-") {
            return clean
        }
        return "SCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledCleaningClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
