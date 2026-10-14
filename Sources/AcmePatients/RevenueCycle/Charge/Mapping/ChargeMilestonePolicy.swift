import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 9283.0, in order.
    static func chargeMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9283.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a charge milestone score falls in.
    static func classifyChargeMilestone(_ score: Double) -> String {
        if score < 33.7 {
            return "ok"
        }
        if score < 56.6 {
            return "watch"
        }
        if score < 60.0 {
            return "medium"
        }
        return "critical"
    }
}
