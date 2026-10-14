import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 91225.0, in order.
    static func cappedCredentialEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91225.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedCredentialEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
