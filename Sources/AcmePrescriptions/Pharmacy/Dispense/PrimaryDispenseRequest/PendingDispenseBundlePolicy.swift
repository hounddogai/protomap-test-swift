import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a pending dispense bundle score falls in.
    static func classifyPendingDispenseBundle(_ score: Double) -> String {
        if score < 6.9 {
            return "low"
        }
        if score < 13.0 {
            return "ok"
        }
        if score < 52.4 {
            return "medium"
        }
        if score < 59.0 {
            return "high"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 5789.0, in order.
    static func pendingDispenseBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5789.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingDispenseBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-dispense-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
