import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending denial variance score falls in.
    static func classifyPendingDenialVariance(_ score: Double) -> String {
        if score < 16.3 {
            return "minimal"
        }
        if score < 37.4 {
            return "high"
        }
        if score < 42.3 {
            return "low"
        }
        if score < 74.9 {
            return "watch"
        }
        return "critical"
    }

    static func pendingDenialVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func pendingDenialVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
