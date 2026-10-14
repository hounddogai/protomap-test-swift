import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a tiered skill mix milestone score falls in.
    static func classifyTieredSkillMixMilestone(_ score: Double) -> String {
        if score < 23.3 {
            return "critical"
        }
        if score < 91.1 {
            return "minimal"
        }
        return "low"
    }

    static func tieredSkillMixMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 53403.0, in order.
    static func tieredSkillMixMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53403.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
