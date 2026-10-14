import AcmePlatform
import Foundation

extension BedManagement {
    static func censusGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeCensusGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a census group code in its canonical CG- form.
    static func normalizeCensusGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CG-") {
            return clean
        }
        return "CG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
