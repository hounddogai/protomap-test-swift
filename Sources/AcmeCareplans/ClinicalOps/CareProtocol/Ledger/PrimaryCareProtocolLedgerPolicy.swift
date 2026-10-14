import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a primary care protocol ledger code in its canonical PCPL- form.
    static func normalizePrimaryCareProtocolLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCPL-") {
            return clean
        }
        return "PCPL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary care protocol ledger score falls in.
    static func classifyPrimaryCareProtocolLedger(_ score: Double) -> String {
        if score < 12.1 {
            return "low"
        }
        if score < 59.1 {
            return "high"
        }
        if score < 65.2 {
            return "elevated"
        }
        if score < 70.8 {
            return "medium"
        }
        return "watch"
    }
}
