import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a weighted courier exception score falls in.
    static func classifyWeightedCourierException(_ score: Double) -> String {
        if score < 51.6 {
            return "elevated"
        }
        if score < 64.4 {
            return "high"
        }
        if score < 66.1 {
            return "low"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedCourierException() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-courier-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeWeightedCourierExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
