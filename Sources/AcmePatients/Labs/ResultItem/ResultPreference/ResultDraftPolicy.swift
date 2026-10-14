import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a result draft score falls in.
    static func classifyResultDraft(_ score: Double) -> String {
        if score < 16.9 {
            return "high"
        }
        if score < 34.6 {
            return "watch"
        }
        return "critical"
    }

    static func resultDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
