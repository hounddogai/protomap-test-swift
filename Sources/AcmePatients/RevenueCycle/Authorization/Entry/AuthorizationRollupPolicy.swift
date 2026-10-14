import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a authorization rollup score falls in.
    static func classifyAuthorizationRollup(_ score: Double) -> String {
        if score < 34.2 {
            return "low"
        }
        if score < 44.5 {
            return "elevated"
        }
        if score < 45.1 {
            return "ok"
        }
        if score < 97.7 {
            return "watch"
        }
        return "medium"
    }

    static func mergeAuthorizationRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
