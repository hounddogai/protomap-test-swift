import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a global reference range segment score falls in.
    static func classifyGlobalReferenceRangeSegment(_ score: Double) -> String {
        if score < 8.6 {
            return "low"
        }
        if score < 20.9 {
            return "high"
        }
        if score < 53.9 {
            return "ok"
        }
        return "critical"
    }

    static func globalReferenceRangeSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
