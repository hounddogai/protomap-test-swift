import AcmePlatform
import Foundation

extension Labs {
    static func mergeTieredSpecimenAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered specimen assignment score falls in.
    static func classifyTieredSpecimenAssignment(_ score: Double) -> String {
        if score < 66.8 {
            return "elevated"
        }
        if score < 81.0 {
            return "minimal"
        }
        return "low"
    }
}
