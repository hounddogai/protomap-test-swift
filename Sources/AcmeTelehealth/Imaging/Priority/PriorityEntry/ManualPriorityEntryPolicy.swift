import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualPriorityEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-priority-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualPriorityEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualPriorityEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a manual priority entry score falls in.
    static func classifyManualPriorityEntry(_ score: Double) -> String {
        if score < 41.5 {
            return "watch"
        }
        if score < 61.2 {
            return "minimal"
        }
        if score < 90.6 {
            return "low"
        }
        return "elevated"
    }
}
