import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func mergeAuthorizationSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a authorization snapshot score falls in.
    static func classifyAuthorizationSnapshot(_ score: Double) -> String {
        if score < 10.9 {
            return "ok"
        }
        if score < 18.6 {
            return "elevated"
        }
        if score < 67.5 {
            return "watch"
        }
        return "high"
    }
}
