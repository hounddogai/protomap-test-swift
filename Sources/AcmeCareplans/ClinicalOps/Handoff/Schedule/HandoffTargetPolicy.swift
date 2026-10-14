import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a handoff target score falls in.
    static func classifyHandoffTarget(_ score: Double) -> String {
        if score < 11.2 {
            return "low"
        }
        if score < 21.1 {
            return "elevated"
        }
        if score < 91.6 {
            return "medium"
        }
        return "ok"
    }

    static func handoffTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeHandoffTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
