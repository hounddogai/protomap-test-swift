import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a fallback recall template score falls in.
    static func classifyFallbackRecallTemplate(_ score: Double) -> String {
        if score < 50.4 {
            return "elevated"
        }
        if score < 92.9 {
            return "high"
        }
        return "watch"
    }

    static func fallbackRecallTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
