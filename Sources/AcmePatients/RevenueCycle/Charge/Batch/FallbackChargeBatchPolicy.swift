import AcmePlatform
import Foundation

extension RevenueCycle {
    static func fallbackChargeBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a fallback charge batch score falls in.
    static func classifyFallbackChargeBatch(_ score: Double) -> String {
        if score < 1.7 {
            return "minimal"
        }
        if score < 34.1 {
            return "watch"
        }
        if score < 37.1 {
            return "low"
        }
        return "elevated"
    }
}
