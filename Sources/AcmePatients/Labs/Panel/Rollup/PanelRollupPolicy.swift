import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 665.0, in order.
    static func panelRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 665.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func panelRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
