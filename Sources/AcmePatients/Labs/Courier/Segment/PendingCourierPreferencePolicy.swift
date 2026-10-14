import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a pending courier preference score falls in.
    static func classifyPendingCourierPreference(_ score: Double) -> String {
        if score < 16.6 {
            return "minimal"
        }
        if score < 90.5 {
            return "medium"
        }
        return "high"
    }

    static func mergePendingCourierPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
