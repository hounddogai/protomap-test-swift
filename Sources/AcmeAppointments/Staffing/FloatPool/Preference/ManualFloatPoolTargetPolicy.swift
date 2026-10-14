import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 62823.0, in order.
    static func manualFloatPoolTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62823.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualFloatPoolTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-float-pool-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a manual float pool target score falls in.
    static func classifyManualFloatPoolTarget(_ score: Double) -> String {
        if score < 7.5 {
            return "elevated"
        }
        if score < 16.1 {
            return "medium"
        }
        if score < 62.0 {
            return "critical"
        }
        return "low"
    }
}
