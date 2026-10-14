import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualAuthorizationMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualAuthorizationMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-authorization-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 3479.0, in order.
    static func manualAuthorizationMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3479.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
