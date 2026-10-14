import AcmePlatform
import Foundation

extension Labs {
    /// Puts a specimen ledger code in its canonical SL- form.
    static func normalizeSpecimenLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SL-") {
            return clean
        }
        return "SL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 2958.0, in order.
    static func specimenLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2958.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
