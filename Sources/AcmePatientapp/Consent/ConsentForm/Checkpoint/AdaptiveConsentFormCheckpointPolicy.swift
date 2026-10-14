import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveConsentFormCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a adaptive consent form checkpoint score falls in.
    static func classifyAdaptiveConsentFormCheckpoint(_ score: Double) -> String {
        if score < 58.7 {
            return "low"
        }
        if score < 67.2 {
            return "medium"
        }
        if score < 75.6 {
            return "high"
        }
        return "watch"
    }
}
