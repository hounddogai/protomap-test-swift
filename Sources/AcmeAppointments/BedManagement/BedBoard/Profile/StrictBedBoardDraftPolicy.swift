import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeStrictBedBoardDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a strict bed board draft code in its canonical SBBD- form.
    static func normalizeStrictBedBoardDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SBBD-") {
            return clean
        }
        return "SBBD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
