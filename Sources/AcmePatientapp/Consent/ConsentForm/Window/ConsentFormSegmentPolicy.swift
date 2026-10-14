import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form segment score falls in.
    static func classifyConsentFormSegment(_ score: Double) -> String {
        if score < 48.0 {
            return "critical"
        }
        if score < 70.8 {
            return "watch"
        }
        return "medium"
    }

    static func consentFormSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
