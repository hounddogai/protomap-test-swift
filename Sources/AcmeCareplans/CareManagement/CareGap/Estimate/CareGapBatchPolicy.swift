import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap batch score falls in.
    static func classifyCareGapBatch(_ score: Double) -> String {
        if score < 5.9 {
            return "medium"
        }
        if score < 63.1 {
            return "high"
        }
        if score < 78.6 {
            return "low"
        }
        return "elevated"
    }

    static func careGapBatchSpan(_ start: Int, end: Int) -> Int {
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
