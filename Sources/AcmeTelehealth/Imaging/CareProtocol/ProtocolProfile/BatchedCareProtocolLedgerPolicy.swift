import AcmePlatform
import Foundation

extension Imaging {
    static func batchedCareProtocolLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a batched care protocol ledger code in its canonical BCPL- form.
    static func normalizeBatchedCareProtocolLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCPL-") {
            return clean
        }
        return "BCPL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
