import AcmePlatform
import Foundation

extension ClinicalOps {
    static func adaptiveTaskManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveTaskManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-task-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeAdaptiveTaskManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive task manifest score falls in.
    static func classifyAdaptiveTaskManifest(_ score: Double) -> String {
        if score < 36.6 {
            return "ok"
        }
        if score < 87.3 {
            return "watch"
        }
        return "high"
    }
}
