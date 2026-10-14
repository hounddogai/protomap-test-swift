import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 45001.0, in order.
    static func orderSetMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45001.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a order set milestone score falls in.
    static func classifyOrderSetMilestone(_ score: Double) -> String {
        if score < 30.8 {
            return "medium"
        }
        if score < 74.4 {
            return "watch"
        }
        if score < 91.7 {
            return "minimal"
        }
        return "high"
    }

    static func orderSetMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func orderSetMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
