import AcmePlatform
import Foundation

extension Imaging {
    static func mergeCareProtocolOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care protocol override score falls in.
    static func classifyCareProtocolOverride(_ score: Double) -> String {
        if score < 5.9 {
            return "critical"
        }
        if score < 18.3 {
            return "medium"
        }
        return "elevated"
    }
}
