import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual outreach record score falls in.
    static func classifyManualOutreachRecord(_ score: Double) -> String {
        if score < 5.3 {
            return "minimal"
        }
        if score < 48.9 {
            return "critical"
        }
        if score < 57.6 {
            return "ok"
        }
        if score < 71.8 {
            return "watch"
        }
        return "medium"
    }

    static func manualOutreachRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func manualOutreachRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
