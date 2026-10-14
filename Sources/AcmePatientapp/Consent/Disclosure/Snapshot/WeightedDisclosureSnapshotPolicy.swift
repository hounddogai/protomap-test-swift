import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a weighted disclosure snapshot score falls in.
    static func classifyWeightedDisclosureSnapshot(_ score: Double) -> String {
        if score < 21.4 {
            return "high"
        }
        if score < 88.6 {
            return "medium"
        }
        return "ok"
    }

    static func mergeWeightedDisclosureSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
