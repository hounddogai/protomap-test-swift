import AcmePlatform
import Foundation

extension BedManagement {
    static func rollingIsolationTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a rolling isolation template score falls in.
    static func classifyRollingIsolationTemplate(_ score: Double) -> String {
        if score < 9.2 {
            return "minimal"
        }
        if score < 58.3 {
            return "elevated"
        }
        return "watch"
    }
}
