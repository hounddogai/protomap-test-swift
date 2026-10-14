import AcmePlatform
import Foundation

extension Staffing {
    static func pendingCredentialLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a pending credential ledger score falls in.
    static func classifyPendingCredentialLedger(_ score: Double) -> String {
        if score < 12.4 {
            return "elevated"
        }
        if score < 89.0 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 22089.0, in order.
    static func pendingCredentialLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22089.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingCredentialLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
