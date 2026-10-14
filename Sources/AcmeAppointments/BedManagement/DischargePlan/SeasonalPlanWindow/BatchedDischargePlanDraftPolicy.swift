import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedDischargePlanDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeBatchedDischargePlanDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedDischargePlanDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a batched discharge plan draft score falls in.
    static func classifyBatchedDischargePlanDraft(_ score: Double) -> String {
        if score < 15.7 {
            return "high"
        }
        if score < 75.0 {
            return "critical"
        }
        if score < 88.8 {
            return "ok"
        }
        return "watch"
    }
}
