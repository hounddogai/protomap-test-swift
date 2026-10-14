import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 94756.0, in order.
    static func worklistLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94756.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
