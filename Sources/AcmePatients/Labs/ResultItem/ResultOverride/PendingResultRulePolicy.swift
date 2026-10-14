import AcmePlatform
import Foundation

extension Labs {
    static func pendingResultRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingResultRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-result-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 98993.0, in order.
    static func pendingResultRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98993.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
