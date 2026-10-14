import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a default acuity plan milestone score falls in.
    static func classifyDefaultAcuityPlanMilestone(_ score: Double) -> String {
        if score < 73.2 {
            return "minimal"
        }
        if score < 76.4 {
            return "high"
        }
        if score < 78.4 {
            return "medium"
        }
        if score < 86.6 {
            return "elevated"
        }
        return "critical"
    }

    static func defaultAcuityPlanMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 49901.0, in order.
    static func defaultAcuityPlanMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49901.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
