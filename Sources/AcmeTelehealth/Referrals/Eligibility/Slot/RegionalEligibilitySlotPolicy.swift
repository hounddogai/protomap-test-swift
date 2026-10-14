import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a regional eligibility slot score falls in.
    static func classifyRegionalEligibilitySlot(_ score: Double) -> String {
        if score < 10.1 {
            return "critical"
        }
        if score < 18.3 {
            return "high"
        }
        if score < 87.9 {
            return "low"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 16549.0, in order.
    static func regionalEligibilitySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16549.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
