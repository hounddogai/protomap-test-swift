import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalIsolationWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-isolation-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 25397.0, in order.
    static func globalIsolationWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 25397.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global isolation window score falls in.
    static func classifyGlobalIsolationWindow(_ score: Double) -> String {
        if score < 46.1 {
            return "high"
        }
        if score < 47.5 {
            return "medium"
        }
        if score < 61.7 {
            return "critical"
        }
        return "ok"
    }
}
