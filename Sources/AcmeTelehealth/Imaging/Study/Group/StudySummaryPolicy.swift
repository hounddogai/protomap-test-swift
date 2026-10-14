import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStudySummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("study-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func studySummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a study summary score falls in.
    static func classifyStudySummary(_ score: Double) -> String {
        if score < 11.3 {
            return "ok"
        }
        if score < 94.1 {
            return "watch"
        }
        return "high"
    }
}
