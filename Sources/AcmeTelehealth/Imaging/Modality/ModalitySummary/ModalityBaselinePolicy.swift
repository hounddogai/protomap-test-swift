import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality baseline score falls in.
    static func classifyModalityBaseline(_ score: Double) -> String {
        if score < 37.3 {
            return "medium"
        }
        if score < 44.8 {
            return "critical"
        }
        return "ok"
    }

    static func mergeModalityBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
