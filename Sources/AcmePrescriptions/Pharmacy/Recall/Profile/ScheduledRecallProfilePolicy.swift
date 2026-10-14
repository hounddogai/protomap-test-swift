import AcmePlatform
import Foundation

extension Pharmacy {
    static func scheduledRecallProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 94306.0, in order.
    static func scheduledRecallProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94306.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledRecallProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledRecallProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-recall-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
