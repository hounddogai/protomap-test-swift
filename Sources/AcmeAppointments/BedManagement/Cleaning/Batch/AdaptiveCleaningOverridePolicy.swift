import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveCleaningOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAdaptiveCleaningOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive cleaning override score falls in.
    static func classifyAdaptiveCleaningOverride(_ score: Double) -> String {
        if score < 33.4 {
            return "watch"
        }
        if score < 81.4 {
            return "ok"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCleaningOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-cleaning-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
