import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a legacy worklist ledger code in its canonical LWL- form.
    static func normalizeLegacyWorklistLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWL-") {
            return clean
        }
        return "LWL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyWorklistLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
