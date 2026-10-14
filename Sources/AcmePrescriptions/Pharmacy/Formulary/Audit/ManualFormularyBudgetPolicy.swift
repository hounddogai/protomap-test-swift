import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualFormularyBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a manual formulary budget score falls in.
    static func classifyManualFormularyBudget(_ score: Double) -> String {
        if score < 26.7 {
            return "watch"
        }
        if score < 52.4 {
            return "high"
        }
        if score < 84.9 {
            return "medium"
        }
        return "elevated"
    }

    static func manualFormularyBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualFormularyBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-formulary-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
