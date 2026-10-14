import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 36413.0, in order.
    static func credentialPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36413.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a credential plan score falls in.
    static func classifyCredentialPlan(_ score: Double) -> String {
        if score < 73.6 {
            return "high"
        }
        if score < 80.5 {
            return "minimal"
        }
        return "ok"
    }
}
