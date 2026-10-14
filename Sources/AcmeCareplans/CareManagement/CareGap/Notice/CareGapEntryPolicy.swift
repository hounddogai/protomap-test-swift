import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeCareGapEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care gap entry score falls in.
    static func classifyCareGapEntry(_ score: Double) -> String {
        if score < 57.6 {
            return "elevated"
        }
        if score < 91.8 {
            return "critical"
        }
        return "medium"
    }
}
