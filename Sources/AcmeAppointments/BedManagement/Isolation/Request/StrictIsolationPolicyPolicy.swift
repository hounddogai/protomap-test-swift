import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictIsolationPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-isolation-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeStrictIsolationPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a strict isolation policy score falls in.
    static func classifyStrictIsolationPolicy(_ score: Double) -> String {
        if score < 17.0 {
            return "high"
        }
        if score < 88.6 {
            return "low"
        }
        if score < 92.8 {
            return "minimal"
        }
        return "medium"
    }
}
