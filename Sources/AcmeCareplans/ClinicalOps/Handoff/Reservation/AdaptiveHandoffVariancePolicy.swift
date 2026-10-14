import AcmePlatform
import Foundation

extension ClinicalOps {
    static func adaptiveHandoffVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a adaptive handoff variance score falls in.
    static func classifyAdaptiveHandoffVariance(_ score: Double) -> String {
        if score < 13.3 {
            return "minimal"
        }
        if score < 62.7 {
            return "critical"
        }
        return "high"
    }

    static func mergeAdaptiveHandoffVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveHandoffVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-handoff-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
