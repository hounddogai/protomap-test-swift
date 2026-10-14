import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a global alert tier code in its canonical GAT- form.
    static func normalizeGlobalAlertTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GAT-") {
            return clean
        }
        return "GAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalAlertTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 63170.0, in order.
    static func globalAlertTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63170.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
