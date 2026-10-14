import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 5538.0, in order.
    static func rollingCareProtocolBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5538.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCareProtocolBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-care-protocol-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
