import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 90095.0, in order.
    static func dischargePlanPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90095.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func dischargePlanPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a discharge plan policy score falls in.
    static func classifyDischargePlanPolicy(_ score: Double) -> String {
        if score < 42.7 {
            return "minimal"
        }
        if score < 55.2 {
            return "low"
        }
        return "medium"
    }
}
