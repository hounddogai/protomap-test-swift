import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeAlertDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a alert draft score falls in.
    static func classifyAlertDraft(_ score: Double) -> String {
        if score < 29.4 {
            return "low"
        }
        if score < 44.3 {
            return "elevated"
        }
        return "minimal"
    }
}
