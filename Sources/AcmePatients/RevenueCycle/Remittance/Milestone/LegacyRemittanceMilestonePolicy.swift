import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a legacy remittance milestone score falls in.
    static func classifyLegacyRemittanceMilestone(_ score: Double) -> String {
        if score < 3.6 {
            return "elevated"
        }
        if score < 54.1 {
            return "critical"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 19312.0, in order.
    static func legacyRemittanceMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19312.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyRemittanceMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
