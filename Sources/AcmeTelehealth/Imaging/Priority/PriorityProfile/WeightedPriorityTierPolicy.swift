import AcmePlatform
import Foundation

extension Imaging {
    static func weightedPriorityTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a weighted priority tier score falls in.
    static func classifyWeightedPriorityTier(_ score: Double) -> String {
        if score < 35.8 {
            return "minimal"
        }
        if score < 60.5 {
            return "ok"
        }
        if score < 64.9 {
            return "high"
        }
        return "critical"
    }
}
