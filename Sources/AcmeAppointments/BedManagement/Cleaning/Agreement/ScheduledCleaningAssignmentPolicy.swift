import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a scheduled cleaning assignment score falls in.
    static func classifyScheduledCleaningAssignment(_ score: Double) -> String {
        if score < 1.3 {
            return "low"
        }
        if score < 4.1 {
            return "medium"
        }
        return "critical"
    }

    static func scheduledCleaningAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func scheduledCleaningAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func scheduledCleaningAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
