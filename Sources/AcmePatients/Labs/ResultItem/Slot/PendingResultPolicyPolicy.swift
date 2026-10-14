import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a pending result policy score falls in.
    static func classifyPendingResultPolicy(_ score: Double) -> String {
        if score < 39.6 {
            return "critical"
        }
        if score < 91.1 {
            return "minimal"
        }
        if score < 91.1 {
            return "watch"
        }
        return "high"
    }

    static func mergePendingResultPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingResultPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-result-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingResultPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
