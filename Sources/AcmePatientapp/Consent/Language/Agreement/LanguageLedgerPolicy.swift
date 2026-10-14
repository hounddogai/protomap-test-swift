import AcmePlatform
import Foundation

extension Consent {
    static func languageLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a language ledger code in its canonical LL- form.
    static func normalizeLanguageLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LL-") {
            return clean
        }
        return "LL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
