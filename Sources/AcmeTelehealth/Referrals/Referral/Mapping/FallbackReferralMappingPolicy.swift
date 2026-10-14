import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 17797.0, in order.
    static func fallbackReferralMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17797.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback referral mapping score falls in.
    static func classifyFallbackReferralMapping(_ score: Double) -> String {
        if score < 15.8 {
            return "minimal"
        }
        if score < 36.7 {
            return "critical"
        }
        if score < 39.3 {
            return "elevated"
        }
        if score < 66.1 {
            return "ok"
        }
        return "low"
    }
}
