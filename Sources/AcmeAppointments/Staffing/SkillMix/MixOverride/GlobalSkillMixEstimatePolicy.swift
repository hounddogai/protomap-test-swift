import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 42341.0, in order.
    static func globalSkillMixEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42341.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global skill mix estimate score falls in.
    static func classifyGlobalSkillMixEstimate(_ score: Double) -> String {
        if score < 12.2 {
            return "low"
        }
        if score < 85.8 {
            return "minimal"
        }
        return "medium"
    }
}
