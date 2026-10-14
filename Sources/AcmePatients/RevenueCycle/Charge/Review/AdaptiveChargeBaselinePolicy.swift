import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a adaptive charge baseline score falls in.
    static func classifyAdaptiveChargeBaseline(_ score: Double) -> String {
        if score < 47.6 {
            return "minimal"
        }
        if score < 79.7 {
            return "low"
        }
        return "ok"
    }

    static func adaptiveChargeBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
