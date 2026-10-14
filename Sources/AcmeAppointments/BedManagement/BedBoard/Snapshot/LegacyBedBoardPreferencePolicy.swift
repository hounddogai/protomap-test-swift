import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a legacy bed board preference score falls in.
    static func classifyLegacyBedBoardPreference(_ score: Double) -> String {
        if score < 32.6 {
            return "critical"
        }
        if score < 38.6 {
            return "watch"
        }
        if score < 73.6 {
            return "high"
        }
        return "medium"
    }

    static func legacyBedBoardPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyBedBoardPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-bed-board-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
