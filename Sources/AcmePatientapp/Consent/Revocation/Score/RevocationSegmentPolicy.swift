import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 1397.0, in order.
    static func revocationSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1397.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a revocation segment score falls in.
    static func classifyRevocationSegment(_ score: Double) -> String {
        if score < 31.1 {
            return "ok"
        }
        if score < 40.7 {
            return "elevated"
        }
        if score < 62.3 {
            return "low"
        }
        if score < 62.6 {
            return "watch"
        }
        return "critical"
    }
}
