import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a global reference range batch score falls in.
    static func classifyGlobalReferenceRangeBatch(_ score: Double) -> String {
        if score < 3.5 {
            return "low"
        }
        if score < 6.4 {
            return "minimal"
        }
        if score < 14.5 {
            return "high"
        }
        return "watch"
    }

    static func mergeGlobalReferenceRangeBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalReferenceRangeBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
