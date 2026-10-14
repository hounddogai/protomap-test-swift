import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualChargeMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 69009.0, in order.
    static func manualChargeMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69009.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual charge mapping score falls in.
    static func classifyManualChargeMapping(_ score: Double) -> String {
        if score < 40.2 {
            return "minimal"
        }
        if score < 96.2 {
            return "medium"
        }
        return "critical"
    }
}
