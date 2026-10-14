import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality group score falls in.
    static func classifyModalityGroup(_ score: Double) -> String {
        if score < 49.5 {
            return "low"
        }
        if score < 52.3 {
            return "medium"
        }
        if score < 75.1 {
            return "ok"
        }
        return "watch"
    }

    static func mergeModalityGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func modalityGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
