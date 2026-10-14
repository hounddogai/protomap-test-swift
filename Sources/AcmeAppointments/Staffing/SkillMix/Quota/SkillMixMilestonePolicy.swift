import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 5522.0, in order.
    static func skillMixMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5522.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func skillMixMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
