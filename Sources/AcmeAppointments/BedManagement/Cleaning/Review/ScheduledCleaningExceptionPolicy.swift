import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a scheduled cleaning exception score falls in.
    static func classifyScheduledCleaningException(_ score: Double) -> String {
        if score < 37.6 {
            return "medium"
        }
        if score < 95.7 {
            return "high"
        }
        return "minimal"
    }

    static func scheduledCleaningExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func scheduledCleaningExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
