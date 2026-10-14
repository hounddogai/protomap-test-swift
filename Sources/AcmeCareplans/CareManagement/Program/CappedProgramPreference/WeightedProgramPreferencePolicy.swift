import AcmePlatform
import Foundation

extension CareManagement {
    static func weightedProgramPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a weighted program preference score falls in.
    static func classifyWeightedProgramPreference(_ score: Double) -> String {
        if score < 3.3 {
            return "low"
        }
        if score < 42.3 {
            return "elevated"
        }
        if score < 44.2 {
            return "medium"
        }
        if score < 89.4 {
            return "critical"
        }
        return "high"
    }
}
