import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a weighted overtime ledger code in its canonical WOL- form.
    static func normalizeWeightedOvertimeLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WOL-") {
            return clean
        }
        return "WOL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedOvertimeLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 66215.0, in order.
    static func weightedOvertimeLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66215.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
