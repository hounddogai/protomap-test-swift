import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a seasonal skill mix segment score falls in.
    static func classifySeasonalSkillMixSegment(_ score: Double) -> String {
        if score < 17.4 {
            return "ok"
        }
        if score < 43.2 {
            return "watch"
        }
        if score < 81.3 {
            return "elevated"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 17597.0, in order.
    static func seasonalSkillMixSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17597.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
