import AcmePlatform
import Foundation

extension Referrals {
    static func followUpBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFollowUpBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("follow-up-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 1719.0, in order.
    static func followUpBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1719.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
