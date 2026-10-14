import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedBedBoardAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a batched bed board allocation score falls in.
    static func classifyBatchedBedBoardAllocation(_ score: Double) -> String {
        if score < 1.1 {
            return "minimal"
        }
        if score < 38.3 {
            return "elevated"
        }
        if score < 89.1 {
            return "high"
        }
        if score < 92.4 {
            return "ok"
        }
        return "low"
    }

    static func mergeBatchedBedBoardAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
