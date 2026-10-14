import AcmePlatform
import Foundation

extension BedManagement {
    static func defaultCleaningDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 53698.0, in order.
    static func defaultCleaningDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53698.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
