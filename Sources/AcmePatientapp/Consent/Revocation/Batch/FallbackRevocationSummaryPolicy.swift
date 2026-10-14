import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 97397.0, in order.
    static func fallbackRevocationSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97397.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback revocation summary score falls in.
    static func classifyFallbackRevocationSummary(_ score: Double) -> String {
        if score < 46.8 {
            return "medium"
        }
        if score < 50.6 {
            return "elevated"
        }
        if score < 69.0 {
            return "minimal"
        }
        return "low"
    }
}
