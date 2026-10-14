import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a rolling interaction digest score falls in.
    static func classifyRollingInteractionDigest(_ score: Double) -> String {
        if score < 1.7 {
            return "ok"
        }
        if score < 2.3 {
            return "low"
        }
        if score < 35.8 {
            return "medium"
        }
        if score < 97.4 {
            return "critical"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 9023.0, in order.
    static func rollingInteractionDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9023.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
