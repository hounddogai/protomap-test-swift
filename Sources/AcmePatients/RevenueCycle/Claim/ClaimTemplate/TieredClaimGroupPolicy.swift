import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a tiered claim group code in its canonical TCG- form.
    static func normalizeTieredClaimGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCG-") {
            return clean
        }
        return "TCG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 92584.0, in order.
    static func tieredClaimGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92584.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
