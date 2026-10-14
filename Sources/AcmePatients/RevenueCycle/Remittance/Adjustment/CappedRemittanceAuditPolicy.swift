import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 26099.0, in order.
    static func cappedRemittanceAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26099.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedRemittanceAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedRemittanceAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-remittance-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func cappedRemittanceAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
