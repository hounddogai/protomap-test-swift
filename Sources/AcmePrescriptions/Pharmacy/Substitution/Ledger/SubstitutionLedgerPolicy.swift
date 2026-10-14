import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeSubstitutionLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a substitution ledger score falls in.
    static func classifySubstitutionLedger(_ score: Double) -> String {
        if score < 21.0 {
            return "ok"
        }
        if score < 30.2 {
            return "minimal"
        }
        if score < 77.1 {
            return "high"
        }
        return "critical"
    }

    /// Puts a substitution ledger code in its canonical SL- form.
    static func normalizeSubstitutionLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SL-") {
            return clean
        }
        return "SL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
