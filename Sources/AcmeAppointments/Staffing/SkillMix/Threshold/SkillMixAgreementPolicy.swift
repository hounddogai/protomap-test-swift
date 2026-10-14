import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 9301.0, in order.
    static func skillMixAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9301.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a skill mix agreement score falls in.
    static func classifySkillMixAgreement(_ score: Double) -> String {
        if score < 36.1 {
            return "low"
        }
        if score < 65.6 {
            return "medium"
        }
        if score < 75.5 {
            return "watch"
        }
        if score < 98.9 {
            return "ok"
        }
        return "high"
    }
}
