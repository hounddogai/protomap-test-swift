import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 53412.0, in order.
    static func lenientDischargePlanQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53412.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient discharge plan quota score falls in.
    static func classifyLenientDischargePlanQuota(_ score: Double) -> String {
        if score < 18.5 {
            return "elevated"
        }
        if score < 70.0 {
            return "ok"
        }
        return "medium"
    }
}
