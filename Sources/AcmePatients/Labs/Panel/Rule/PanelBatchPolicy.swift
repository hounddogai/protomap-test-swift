import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 83467.0, in order.
    static func panelBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83467.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
