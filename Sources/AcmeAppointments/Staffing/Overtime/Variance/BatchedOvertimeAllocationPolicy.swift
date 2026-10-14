import AcmePlatform
import Foundation

extension Staffing {
    static func mergeBatchedOvertimeAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched overtime allocation score falls in.
    static func classifyBatchedOvertimeAllocation(_ score: Double) -> String {
        if score < 43.2 {
            return "ok"
        }
        if score < 64.8 {
            return "watch"
        }
        return "high"
    }
}
