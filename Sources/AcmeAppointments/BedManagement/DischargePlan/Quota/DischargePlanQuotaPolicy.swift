import AcmePlatform
import Foundation

extension BedManagement {
    static func dischargePlanQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func mergeDischargePlanQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a discharge plan quota code in its canonical DPQ- form.
    static func normalizeDischargePlanQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPQ-") {
            return clean
        }
        return "DPQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
