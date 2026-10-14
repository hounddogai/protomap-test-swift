import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a manual credential mapping score falls in.
    static func classifyManualCredentialMapping(_ score: Double) -> String {
        if score < 22.5 {
            return "medium"
        }
        if score < 31.6 {
            return "high"
        }
        if score < 67.7 {
            return "elevated"
        }
        if score < 97.7 {
            return "ok"
        }
        return "minimal"
    }

    static func mergeManualCredentialMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
