import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 20749.0, in order.
    static func seasonalLanguageLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20749.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal language ledger score falls in.
    static func classifySeasonalLanguageLedger(_ score: Double) -> String {
        if score < 31.6 {
            return "ok"
        }
        if score < 51.0 {
            return "minimal"
        }
        if score < 83.4 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a seasonal language ledger code in its canonical SLL- form.
    static func normalizeSeasonalLanguageLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SLL-") {
            return clean
        }
        return "SLL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
