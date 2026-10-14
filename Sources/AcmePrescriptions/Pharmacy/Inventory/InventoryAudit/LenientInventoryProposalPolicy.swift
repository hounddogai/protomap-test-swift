import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientInventoryProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a lenient inventory proposal code in its canonical LIP- form.
    static func normalizeLenientInventoryProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIP-") {
            return clean
        }
        return "LIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientInventoryProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 89677.0, in order.
    static func lenientInventoryProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89677.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
