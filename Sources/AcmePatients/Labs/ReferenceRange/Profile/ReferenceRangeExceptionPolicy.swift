import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a reference range exception score falls in.
    static func classifyReferenceRangeException(_ score: Double) -> String {
        if score < 17.0 {
            return "high"
        }
        if score < 72.3 {
            return "medium"
        }
        if score < 92.3 {
            return "ok"
        }
        if score < 96.3 {
            return "elevated"
        }
        return "low"
    }

    static func mergeReferenceRangeExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
