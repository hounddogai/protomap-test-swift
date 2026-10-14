import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score ledger code in its canonical RSL- form.
    static func normalizeRiskScoreLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSL-") {
            return clean
        }
        return "RSL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a risk score ledger score falls in.
    static func classifyRiskScoreLedger(_ score: Double) -> String {
        if score < 62.6 {
            return "low"
        }
        if score < 66.7 {
            return "minimal"
        }
        if score < 79.2 {
            return "ok"
        }
        return "critical"
    }
}
