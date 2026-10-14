import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a handoff quota score falls in.
    static func classifyHandoffQuota(_ score: Double) -> String {
        if score < 16.5 {
            return "medium"
        }
        if score < 67.9 {
            return "watch"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeHandoffQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
