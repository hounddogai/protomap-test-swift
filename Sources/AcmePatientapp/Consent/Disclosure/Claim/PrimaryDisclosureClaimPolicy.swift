import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 51648.0, in order.
    static func primaryDisclosureClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51648.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary disclosure claim score falls in.
    static func classifyPrimaryDisclosureClaim(_ score: Double) -> String {
        if score < 3.5 {
            return "watch"
        }
        if score < 60.5 {
            return "low"
        }
        if score < 80.9 {
            return "elevated"
        }
        if score < 98.0 {
            return "minimal"
        }
        return "ok"
    }
}
