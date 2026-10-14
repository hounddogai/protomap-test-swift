import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a strict skill mix review score falls in.
    static func classifyStrictSkillMixReview(_ score: Double) -> String {
        if score < 2.7 {
            return "medium"
        }
        if score < 32.4 {
            return "high"
        }
        if score < 35.1 {
            return "critical"
        }
        if score < 86.3 {
            return "elevated"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 71960.0, in order.
    static func strictSkillMixReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71960.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictSkillMixReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
