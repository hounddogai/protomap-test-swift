import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness threshold score falls in.
    static func classifyWitnessThreshold(_ score: Double) -> String {
        if score < 46.6 {
            return "watch"
        }
        if score < 80.6 {
            return "critical"
        }
        return "minimal"
    }

    static func mergeWitnessThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
