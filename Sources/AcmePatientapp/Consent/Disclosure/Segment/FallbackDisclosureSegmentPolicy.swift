import AcmePlatform
import Foundation

extension Consent {
    static func fallbackDisclosureSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func fallbackDisclosureSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a fallback disclosure segment score falls in.
    static func classifyFallbackDisclosureSegment(_ score: Double) -> String {
        if score < 9.4 {
            return "elevated"
        }
        if score < 99.4 {
            return "critical"
        }
        return "low"
    }
}
