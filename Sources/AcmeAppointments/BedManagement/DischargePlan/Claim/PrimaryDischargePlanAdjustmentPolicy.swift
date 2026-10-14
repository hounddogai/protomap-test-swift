import AcmePlatform
import Foundation

extension BedManagement {
    static func primaryDischargePlanAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func mergePrimaryDischargePlanAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary discharge plan adjustment code in its canonical PDPA- form.
    static func normalizePrimaryDischargePlanAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDPA-") {
            return clean
        }
        return "PDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
