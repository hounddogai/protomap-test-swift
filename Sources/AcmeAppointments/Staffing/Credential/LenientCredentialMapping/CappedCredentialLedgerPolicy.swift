import AcmePlatform
import Foundation

extension Staffing {
    static func cappedCredentialLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 71256.0, in order.
    static func cappedCredentialLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71256.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedCredentialLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
