import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a adaptive study ledger code in its canonical ASL- form.
    static func normalizeAdaptiveStudyLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASL-") {
            return clean
        }
        return "ASL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive study ledger score falls in.
    static func classifyAdaptiveStudyLedger(_ score: Double) -> String {
        if score < 18.3 {
            return "elevated"
        }
        if score < 46.8 {
            return "medium"
        }
        if score < 59.4 {
            return "ok"
        }
        if score < 96.2 {
            return "watch"
        }
        return "high"
    }

    static func mergeAdaptiveStudyLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
