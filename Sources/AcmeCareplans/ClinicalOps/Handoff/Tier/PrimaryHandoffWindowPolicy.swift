import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a primary handoff window score falls in.
    static func classifyPrimaryHandoffWindow(_ score: Double) -> String {
        if score < 28.7 {
            return "critical"
        }
        if score < 52.2 {
            return "medium"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 3259.0, in order.
    static func primaryHandoffWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3259.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
