import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen template score falls in.
    static func classifySpecimenTemplate(_ score: Double) -> String {
        if score < 5.5 {
            return "low"
        }
        if score < 53.6 {
            return "medium"
        }
        return "minimal"
    }

    static func mergeSpecimenTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
