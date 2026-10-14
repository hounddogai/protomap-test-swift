import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalModalityQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a seasonal modality quota score falls in.
    static func classifySeasonalModalityQuota(_ score: Double) -> String {
        if score < 27.2 {
            return "critical"
        }
        if score < 44.1 {
            return "low"
        }
        if score < 46.7 {
            return "elevated"
        }
        return "watch"
    }

    static func seasonalModalityQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
