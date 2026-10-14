import AcmePlatform
import Foundation

extension Labs {
    static func strictResultWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a strict result window score falls in.
    static func classifyStrictResultWindow(_ score: Double) -> String {
        if score < 9.2 {
            return "medium"
        }
        if score < 39.4 {
            return "high"
        }
        if score < 50.3 {
            return "elevated"
        }
        if score < 56.0 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictResultWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-result-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeStrictResultWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
