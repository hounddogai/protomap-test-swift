import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 24852.0, in order.
    static func pendingStatementProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24852.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a pending statement proposal code in its canonical PSP- form.
    static func normalizePendingStatementProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSP-") {
            return clean
        }
        return "PSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
