import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a inventory ledger score falls in.
    static func classifyInventoryLedger(_ score: Double) -> String {
        if score < 22.8 {
            return "ok"
        }
        if score < 70.4 {
            return "critical"
        }
        if score < 75.8 {
            return "high"
        }
        return "medium"
    }

    /// Puts a inventory ledger code in its canonical IL- form.
    static func normalizeInventoryLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IL-") {
            return clean
        }
        return "IL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 15477.0, in order.
    static func inventoryLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15477.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
