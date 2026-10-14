import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 29858.0, in order.
    static func statementTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29858.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStatementTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a statement tier code in its canonical ST- form.
    static func normalizeStatementTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ST-") {
            return clean
        }
        return "ST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
