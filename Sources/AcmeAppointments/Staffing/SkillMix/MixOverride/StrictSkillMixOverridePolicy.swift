import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 38657.0, in order.
    static func strictSkillMixOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38657.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict skill mix override score falls in.
    static func classifyStrictSkillMixOverride(_ score: Double) -> String {
        if score < 46.8 {
            return "watch"
        }
        if score < 84.7 {
            return "low"
        }
        return "ok"
    }
}
