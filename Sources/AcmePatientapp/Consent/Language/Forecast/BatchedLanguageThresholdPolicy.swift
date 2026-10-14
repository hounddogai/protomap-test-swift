import AcmePlatform
import Foundation

extension Consent {
    static func batchedLanguageThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a batched language threshold score falls in.
    static func classifyBatchedLanguageThreshold(_ score: Double) -> String {
        if score < 2.4 {
            return "minimal"
        }
        if score < 40.4 {
            return "critical"
        }
        if score < 41.9 {
            return "medium"
        }
        if score < 46.1 {
            return "ok"
        }
        return "low"
    }
}
