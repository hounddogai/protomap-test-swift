import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a weighted bed board claim code in its canonical WBBC- form.
    static func normalizeWeightedBedBoardClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WBBC-") {
            return clean
        }
        return "WBBC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedBedBoardClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func mergeWeightedBedBoardClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
