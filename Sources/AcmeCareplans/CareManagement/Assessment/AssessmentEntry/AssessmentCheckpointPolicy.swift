import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeAssessmentCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a assessment checkpoint score falls in.
    static func classifyAssessmentCheckpoint(_ score: Double) -> String {
        if score < 32.9 {
            return "low"
        }
        if score < 60.1 {
            return "minimal"
        }
        return "medium"
    }
}
