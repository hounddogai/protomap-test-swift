import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a tiered task target score falls in.
    static func classifyTieredTaskTarget(_ score: Double) -> String {
        if score < 33.2 {
            return "elevated"
        }
        if score < 64.2 {
            return "low"
        }
        return "ok"
    }

    static func tieredTaskTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredTaskTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-task-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeTieredTaskTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
