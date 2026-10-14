import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a lenient acuity plan baseline score falls in.
    static func classifyLenientAcuityPlanBaseline(_ score: Double) -> String {
        if score < 68.8 {
            return "ok"
        }
        if score < 69.3 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 19758.0, in order.
    static func lenientAcuityPlanBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19758.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
