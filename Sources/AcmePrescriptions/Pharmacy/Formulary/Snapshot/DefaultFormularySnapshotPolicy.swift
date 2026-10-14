import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDefaultFormularySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default formulary snapshot score falls in.
    static func classifyDefaultFormularySnapshot(_ score: Double) -> String {
        if score < 2.5 {
            return "low"
        }
        if score < 42.8 {
            return "medium"
        }
        if score < 98.2 {
            return "high"
        }
        return "elevated"
    }
}
