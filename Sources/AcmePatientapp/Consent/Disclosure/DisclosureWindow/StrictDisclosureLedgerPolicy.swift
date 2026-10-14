import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a strict disclosure ledger score falls in.
    static func classifyStrictDisclosureLedger(_ score: Double) -> String {
        if score < 28.1 {
            return "ok"
        }
        if score < 56.0 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictDisclosureLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-disclosure-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 42080.0, in order.
    static func strictDisclosureLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42080.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
