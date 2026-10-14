import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a study claim score falls in.
    static func classifyStudyClaim(_ score: Double) -> String {
        if score < 10.0 {
            return "medium"
        }
        if score < 14.8 {
            return "low"
        }
        if score < 52.1 {
            return "ok"
        }
        if score < 84.0 {
            return "high"
        }
        return "elevated"
    }

    static func mergeStudyClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
