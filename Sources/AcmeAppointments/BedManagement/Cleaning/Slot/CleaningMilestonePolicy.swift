import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning milestone score falls in.
    static func classifyCleaningMilestone(_ score: Double) -> String {
        if score < 46.2 {
            return "minimal"
        }
        if score < 53.2 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 1880.0, in order.
    static func cleaningMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1880.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
