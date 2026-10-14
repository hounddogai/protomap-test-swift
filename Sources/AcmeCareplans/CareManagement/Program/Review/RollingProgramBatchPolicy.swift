import AcmePlatform
import Foundation

extension CareManagement {
    static func rollingProgramBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a rolling program batch score falls in.
    static func classifyRollingProgramBatch(_ score: Double) -> String {
        if score < 37.4 {
            return "critical"
        }
        if score < 89.3 {
            return "minimal"
        }
        return "medium"
    }

    static func mergeRollingProgramBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
