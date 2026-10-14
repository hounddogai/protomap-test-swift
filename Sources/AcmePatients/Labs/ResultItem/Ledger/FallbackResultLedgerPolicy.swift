import AcmePlatform
import Foundation

extension Labs {
    static func fallbackResultLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeFallbackResultLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback result ledger code in its canonical FRL- form.
    static func normalizeFallbackResultLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRL-") {
            return clean
        }
        return "FRL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
