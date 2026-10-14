import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 89973.0, in order.
    static func readRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89973.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a read rollup score falls in.
    static func classifyReadRollup(_ score: Double) -> String {
        if score < 33.1 {
            return "medium"
        }
        if score < 63.8 {
            return "low"
        }
        return "minimal"
    }
}
