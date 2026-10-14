import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingChargeSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-charge-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingChargeSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a rolling charge segment score falls in.
    static func classifyRollingChargeSegment(_ score: Double) -> String {
        if score < 36.9 {
            return "high"
        }
        if score < 43.1 {
            return "minimal"
        }
        if score < 94.9 {
            return "low"
        }
        return "medium"
    }

    static func mergeRollingChargeSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
