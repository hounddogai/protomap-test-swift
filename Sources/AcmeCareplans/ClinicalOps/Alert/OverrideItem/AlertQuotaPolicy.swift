import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeAlertQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a alert quota score falls in.
    static func classifyAlertQuota(_ score: Double) -> String {
        if score < 10.5 {
            return "medium"
        }
        if score < 46.4 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
