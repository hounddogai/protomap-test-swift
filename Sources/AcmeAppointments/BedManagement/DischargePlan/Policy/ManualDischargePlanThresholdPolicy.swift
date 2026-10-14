import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a manual discharge plan threshold score falls in.
    static func classifyManualDischargePlanThreshold(_ score: Double) -> String {
        if score < 25.5 {
            return "critical"
        }
        if score < 72.7 {
            return "minimal"
        }
        if score < 73.4 {
            return "elevated"
        }
        if score < 77.5 {
            return "medium"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 15382.0, in order.
    static func manualDischargePlanThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15382.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
