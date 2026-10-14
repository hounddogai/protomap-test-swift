import AcmePlatform
import Foundation

extension ClinicalOps {
    static func regionalOrderSetRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Puts a regional order set rollup code in its canonical ROSR- form.
    static func normalizeRegionalOrderSetRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROSR-") {
            return clean
        }
        return "ROSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalOrderSetRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
