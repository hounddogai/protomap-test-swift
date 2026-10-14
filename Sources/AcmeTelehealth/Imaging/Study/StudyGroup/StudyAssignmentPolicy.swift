import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a study assignment score falls in.
    static func classifyStudyAssignment(_ score: Double) -> String {
        if score < 3.8 {
            return "critical"
        }
        if score < 23.8 {
            return "high"
        }
        if score < 89.5 {
            return "elevated"
        }
        return "minimal"
    }

    static func studyAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
