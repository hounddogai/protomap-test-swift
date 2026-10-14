import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a pending recall ledger code in its canonical PRL- form.
    static func normalizePendingRecallLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRL-") {
            return clean
        }
        return "PRL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingRecallLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 99192.0, in order.
    static func pendingRecallLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99192.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
