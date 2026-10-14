import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a seasonal read estimate score falls in.
    static func classifySeasonalReadEstimate(_ score: Double) -> String {
        if score < 68.5 {
            return "ok"
        }
        if score < 83.3 {
            return "elevated"
        }
        return "critical"
    }

    static func seasonalReadEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
