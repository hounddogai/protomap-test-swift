import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 50556.0, in order.
    static func cappedRevocationLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50556.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped revocation ledger score falls in.
    static func classifyCappedRevocationLedger(_ score: Double) -> String {
        if score < 74.3 {
            return "minimal"
        }
        if score < 96.6 {
            return "medium"
        }
        return "elevated"
    }

    static func mergeCappedRevocationLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
