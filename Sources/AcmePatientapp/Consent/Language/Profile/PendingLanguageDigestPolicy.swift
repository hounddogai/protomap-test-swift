import AcmePlatform
import Foundation

extension Consent {
    static func pendingLanguageDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func pendingLanguageDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a pending language digest score falls in.
    static func classifyPendingLanguageDigest(_ score: Double) -> String {
        if score < 58.8 {
            return "medium"
        }
        if score < 97.6 {
            return "ok"
        }
        return "critical"
    }
}
