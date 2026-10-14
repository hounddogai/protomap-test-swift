import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a strict transfer score score falls in.
    static func classifyStrictTransferScore(_ score: Double) -> String {
        if score < 42.9 {
            return "watch"
        }
        if score < 43.2 {
            return "critical"
        }
        if score < 47.0 {
            return "minimal"
        }
        if score < 93.7 {
            return "medium"
        }
        return "low"
    }

    static func mergeStrictTransferScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictTransferScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-transfer-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
