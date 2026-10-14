import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 558.0, in order.
    static func inventoryBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 558.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
