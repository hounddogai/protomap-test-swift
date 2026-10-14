import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeManualDenialTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual denial template score falls in.
    static func classifyManualDenialTemplate(_ score: Double) -> String {
        if score < 1.8 {
            return "ok"
        }
        if score < 64.1 {
            return "low"
        }
        if score < 91.2 {
            return "medium"
        }
        return "elevated"
    }
}
