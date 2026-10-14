import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness ledger code in its canonical WL- form.
    static func normalizeWitnessLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WL-") {
            return clean
        }
        return "WL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func witnessLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
