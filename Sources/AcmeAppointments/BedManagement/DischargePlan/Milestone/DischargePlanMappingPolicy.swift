import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a discharge plan mapping code in its canonical DPM- form.
    static func normalizeDischargePlanMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPM-") {
            return clean
        }
        return "DPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dischargePlanMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
