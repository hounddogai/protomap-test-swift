import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap rollup score falls in.
    static func classifyCareGapRollup(_ score: Double) -> String {
        if score < 47.0 {
            return "high"
        }
        if score < 53.5 {
            return "medium"
        }
        return "low"
    }

    static func careGapRollupSpan(_ start: Int, end: Int) -> Int {
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
