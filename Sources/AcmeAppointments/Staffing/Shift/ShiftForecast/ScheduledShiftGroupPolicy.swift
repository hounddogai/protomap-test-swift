import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledShiftGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a scheduled shift group score falls in.
    static func classifyScheduledShiftGroup(_ score: Double) -> String {
        if score < 35.5 {
            return "ok"
        }
        if score < 59.1 {
            return "elevated"
        }
        if score < 60.3 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 77906.0, in order.
    static func scheduledShiftGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77906.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledShiftGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-shift-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
