import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeTaskManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a task manifest score falls in.
    static func classifyTaskManifest(_ score: Double) -> String {
        if score < 55.3 {
            return "low"
        }
        if score < 77.9 {
            return "critical"
        }
        return "watch"
    }
}
