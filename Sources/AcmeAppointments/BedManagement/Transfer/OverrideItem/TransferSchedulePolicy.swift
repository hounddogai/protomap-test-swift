import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 11197.0, in order.
    static func transferScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11197.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func transferScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
