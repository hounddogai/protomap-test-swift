import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a pending task schedule score falls in.
    static func classifyPendingTaskSchedule(_ score: Double) -> String {
        if score < 19.2 {
            return "elevated"
        }
        if score < 67.6 {
            return "ok"
        }
        if score < 75.4 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 62432.0, in order.
    static func pendingTaskScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62432.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
