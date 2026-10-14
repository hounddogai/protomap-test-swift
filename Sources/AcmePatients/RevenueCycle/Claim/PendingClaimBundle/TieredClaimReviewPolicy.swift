import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 52589.0, in order.
    static func tieredClaimReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52589.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered claim review code in its canonical TCR- form.
    static func normalizeTieredClaimReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCR-") {
            return clean
        }
        return "TCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
