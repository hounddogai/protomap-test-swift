import AcmePlatform
import Foundation

extension Pharmacy {
    static func regionalFormularyMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a regional formulary milestone code in its canonical RFM- form.
    static func normalizeRegionalFormularyMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFM-") {
            return clean
        }
        return "RFM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalFormularyMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
