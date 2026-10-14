import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a strict result claim score falls in.
    static func classifyStrictResultClaim(_ score: Double) -> String {
        if score < 17.2 {
            return "critical"
        }
        if score < 70.7 {
            return "watch"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictResultClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-result-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictResultClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeStrictResultClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
