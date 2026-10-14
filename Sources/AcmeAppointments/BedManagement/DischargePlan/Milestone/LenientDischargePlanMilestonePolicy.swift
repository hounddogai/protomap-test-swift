import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 63092.0, in order.
    static func lenientDischargePlanMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63092.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientDischargePlanMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a lenient discharge plan milestone score falls in.
    static func classifyLenientDischargePlanMilestone(_ score: Double) -> String {
        if score < 38.4 {
            return "elevated"
        }
        if score < 66.2 {
            return "medium"
        }
        return "minimal"
    }
}
