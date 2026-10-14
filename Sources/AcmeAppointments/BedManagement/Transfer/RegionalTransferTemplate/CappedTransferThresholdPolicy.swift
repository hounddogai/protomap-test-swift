import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a capped transfer threshold score falls in.
    static func classifyCappedTransferThreshold(_ score: Double) -> String {
        if score < 62.9 {
            return "low"
        }
        if score < 69.8 {
            return "medium"
        }
        if score < 85.7 {
            return "critical"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 26157.0, in order.
    static func cappedTransferThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26157.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
