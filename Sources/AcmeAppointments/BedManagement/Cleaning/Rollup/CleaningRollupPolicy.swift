import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 97854.0, in order.
    static func cleaningRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97854.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a cleaning rollup score falls in.
    static func classifyCleaningRollup(_ score: Double) -> String {
        if score < 8.6 {
            return "ok"
        }
        if score < 20.0 {
            return "low"
        }
        if score < 72.4 {
            return "medium"
        }
        if score < 72.4 {
            return "elevated"
        }
        return "minimal"
    }
}
