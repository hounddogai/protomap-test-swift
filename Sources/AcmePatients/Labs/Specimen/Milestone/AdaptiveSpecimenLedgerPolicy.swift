import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a adaptive specimen ledger score falls in.
    static func classifyAdaptiveSpecimenLedger(_ score: Double) -> String {
        if score < 23.9 {
            return "medium"
        }
        if score < 86.3 {
            return "minimal"
        }
        return "high"
    }

    /// Puts a adaptive specimen ledger code in its canonical ASL- form.
    static func normalizeAdaptiveSpecimenLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASL-") {
            return clean
        }
        return "ASL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 55936.0, in order.
    static func adaptiveSpecimenLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
