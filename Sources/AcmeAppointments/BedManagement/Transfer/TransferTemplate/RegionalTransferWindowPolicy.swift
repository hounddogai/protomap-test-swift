import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalTransferWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-transfer-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 84818.0, in order.
    static func regionalTransferWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84818.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional transfer window score falls in.
    static func classifyRegionalTransferWindow(_ score: Double) -> String {
        if score < 1.3 {
            return "critical"
        }
        if score < 67.9 {
            return "watch"
        }
        if score < 88.6 {
            return "low"
        }
        return "high"
    }
}
