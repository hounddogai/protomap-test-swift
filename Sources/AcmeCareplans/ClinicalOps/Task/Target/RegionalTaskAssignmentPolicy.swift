import AcmePlatform
import Foundation

extension ClinicalOps {
    static func regionalTaskAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a regional task assignment score falls in.
    static func classifyRegionalTaskAssignment(_ score: Double) -> String {
        if score < 22.5 {
            return "high"
        }
        if score < 55.5 {
            return "medium"
        }
        if score < 56.3 {
            return "elevated"
        }
        if score < 56.9 {
            return "low"
        }
        return "critical"
    }
}
