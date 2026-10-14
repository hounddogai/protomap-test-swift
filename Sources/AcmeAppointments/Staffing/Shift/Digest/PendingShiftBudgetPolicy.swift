import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a pending shift budget score falls in.
    static func classifyPendingShiftBudget(_ score: Double) -> String {
        if score < 26.0 {
            return "elevated"
        }
        if score < 38.9 {
            return "watch"
        }
        if score < 65.5 {
            return "minimal"
        }
        if score < 86.8 {
            return "critical"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 64530.0, in order.
    static func pendingShiftBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64530.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
