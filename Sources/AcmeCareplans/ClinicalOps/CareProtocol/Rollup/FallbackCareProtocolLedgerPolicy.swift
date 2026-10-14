import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a fallback care protocol ledger code in its canonical FCPL- form.
    static func normalizeFallbackCareProtocolLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCPL-") {
            return clean
        }
        return "FCPL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFallbackCareProtocolLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
