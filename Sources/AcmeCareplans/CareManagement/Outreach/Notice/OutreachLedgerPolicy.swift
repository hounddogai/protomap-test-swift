import AcmePlatform
import Foundation

extension CareManagement {
    static func outreachLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a outreach ledger code in its canonical OL- form.
    static func normalizeOutreachLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OL-") {
            return clean
        }
        return "OL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
