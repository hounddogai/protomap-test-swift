import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning group score falls in.
    static func classifyCleaningGroup(_ score: Double) -> String {
        if score < 35.0 {
            return "minimal"
        }
        if score < 63.1 {
            return "medium"
        }
        if score < 90.6 {
            return "high"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 31771.0, in order.
    static func cleaningGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31771.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
