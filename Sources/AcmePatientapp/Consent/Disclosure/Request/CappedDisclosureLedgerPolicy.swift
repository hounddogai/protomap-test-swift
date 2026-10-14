import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a capped disclosure ledger score falls in.
    static func classifyCappedDisclosureLedger(_ score: Double) -> String {
        if score < 54.3 {
            return "watch"
        }
        if score < 55.2 {
            return "minimal"
        }
        return "high"
    }

    static func cappedDisclosureLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedDisclosureLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-disclosure-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 49876.0, in order.
    static func cappedDisclosureLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49876.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
