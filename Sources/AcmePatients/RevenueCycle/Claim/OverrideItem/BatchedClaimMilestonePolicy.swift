import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 82120.0, in order.
    static func batchedClaimMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82120.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched claim milestone code in its canonical BCM- form.
    static func normalizeBatchedClaimMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCM-") {
            return clean
        }
        return "BCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
