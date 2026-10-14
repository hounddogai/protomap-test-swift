import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer tier score falls in.
    static func classifyTransferTier(_ score: Double) -> String {
        if score < 17.0 {
            return "elevated"
        }
        if score < 66.8 {
            return "ok"
        }
        if score < 80.4 {
            return "minimal"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 64308.0, in order.
    static func transferTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64308.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
