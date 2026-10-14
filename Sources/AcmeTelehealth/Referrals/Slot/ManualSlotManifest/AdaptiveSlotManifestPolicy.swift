import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 98336.0, in order.
    static func adaptiveSlotManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98336.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a adaptive slot manifest score falls in.
    static func classifyAdaptiveSlotManifest(_ score: Double) -> String {
        if score < 62.4 {
            return "watch"
        }
        if score < 78.0 {
            return "low"
        }
        if score < 95.1 {
            return "minimal"
        }
        return "high"
    }
}
