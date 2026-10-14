import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 83631.0, in order.
    static func fallbackCareProtocolAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83631.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback care protocol audit score falls in.
    static func classifyFallbackCareProtocolAudit(_ score: Double) -> String {
        if score < 12.0 {
            return "elevated"
        }
        if score < 54.3 {
            return "high"
        }
        if score < 82.4 {
            return "critical"
        }
        return "low"
    }
}
