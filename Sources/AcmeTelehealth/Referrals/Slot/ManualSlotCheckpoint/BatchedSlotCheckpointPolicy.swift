import AcmePlatform
import Foundation

extension Referrals {
    static func mergeBatchedSlotCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched slot checkpoint score falls in.
    static func classifyBatchedSlotCheckpoint(_ score: Double) -> String {
        if score < 42.4 {
            return "high"
        }
        if score < 71.3 {
            return "low"
        }
        if score < 91.8 {
            return "ok"
        }
        return "watch"
    }
}
