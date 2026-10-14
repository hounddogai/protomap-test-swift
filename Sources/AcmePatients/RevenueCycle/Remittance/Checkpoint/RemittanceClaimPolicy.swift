import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 32325.0, in order.
    static func remittanceClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32325.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
