import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalWorklistAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a seasonal worklist assignment score falls in.
    static func classifySeasonalWorklistAssignment(_ score: Double) -> String {
        if score < 16.3 {
            return "high"
        }
        if score < 22.2 {
            return "medium"
        }
        if score < 44.8 {
            return "critical"
        }
        if score < 50.3 {
            return "ok"
        }
        return "watch"
    }
}
