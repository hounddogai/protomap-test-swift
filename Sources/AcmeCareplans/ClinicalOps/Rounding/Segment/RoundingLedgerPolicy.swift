import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding ledger score falls in.
    static func classifyRoundingLedger(_ score: Double) -> String {
        if score < 13.8 {
            return "elevated"
        }
        if score < 80.7 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a rounding ledger code in its canonical RL- form.
    static func normalizeRoundingLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RL-") {
            return clean
        }
        return "RL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
