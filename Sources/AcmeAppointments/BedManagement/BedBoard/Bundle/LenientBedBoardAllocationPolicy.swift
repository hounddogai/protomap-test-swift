import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient bed board allocation code in its canonical LBBA- form.
    static func normalizeLenientBedBoardAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LBBA-") {
            return clean
        }
        return "LBBA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLenientBedBoardAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
