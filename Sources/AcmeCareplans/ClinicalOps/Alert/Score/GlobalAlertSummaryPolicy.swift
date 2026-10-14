import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a global alert summary score falls in.
    static func classifyGlobalAlertSummary(_ score: Double) -> String {
        if score < 25.1 {
            return "ok"
        }
        if score < 78.8 {
            return "medium"
        }
        if score < 79.3 {
            return "high"
        }
        if score < 85.9 {
            return "minimal"
        }
        return "elevated"
    }

    static func globalAlertSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
