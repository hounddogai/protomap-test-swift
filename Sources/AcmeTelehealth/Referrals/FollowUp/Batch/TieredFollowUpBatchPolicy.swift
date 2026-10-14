import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 4325.0, in order.
    static func tieredFollowUpBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4325.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered follow up batch code in its canonical TFUB- form.
    static func normalizeTieredFollowUpBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TFUB-") {
            return clean
        }
        return "TFUB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredFollowUpBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
