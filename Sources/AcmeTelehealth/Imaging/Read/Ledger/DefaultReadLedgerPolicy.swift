import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a default read ledger code in its canonical DRL- form.
    static func normalizeDefaultReadLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRL-") {
            return clean
        }
        return "DRL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultReadLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
