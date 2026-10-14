import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 52688.0, in order.
    static func resultAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52688.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a result audit score falls in.
    static func classifyResultAudit(_ score: Double) -> String {
        if score < 27.8 {
            return "low"
        }
        if score < 39.9 {
            return "critical"
        }
        if score < 72.9 {
            return "watch"
        }
        if score < 82.3 {
            return "minimal"
        }
        return "elevated"
    }
}
