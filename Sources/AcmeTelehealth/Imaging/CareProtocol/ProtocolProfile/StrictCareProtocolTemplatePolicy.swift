import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a strict care protocol template score falls in.
    static func classifyStrictCareProtocolTemplate(_ score: Double) -> String {
        if score < 49.0 {
            return "high"
        }
        if score < 63.6 {
            return "watch"
        }
        return "medium"
    }

    static func mergeStrictCareProtocolTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
