import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 87650.0, in order.
    static func batchedTransferClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87650.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedTransferClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
