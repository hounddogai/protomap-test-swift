import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilitySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a eligibility snapshot score falls in.
    static func classifyEligibilitySnapshot(_ score: Double) -> String {
        if score < 11.2 {
            return "watch"
        }
        if score < 29.2 {
            return "minimal"
        }
        if score < 30.6 {
            return "medium"
        }
        if score < 63.4 {
            return "elevated"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilitySnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 57896.0, in order.
    static func eligibilitySnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57896.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
