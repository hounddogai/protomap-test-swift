import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a follow up audit score falls in.
    static func classifyFollowUpAudit(_ score: Double) -> String {
        if score < 21.2 {
            return "high"
        }
        if score < 91.4 {
            return "elevated"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 39802.0, in order.
    static func followUpAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39802.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func followUpAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
