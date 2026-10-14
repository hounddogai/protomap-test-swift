import AcmePlatform
import Foundation

extension Labs {
    static func mergeSpecimenPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func specimenPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a specimen preference score falls in.
    static func classifySpecimenPreference(_ score: Double) -> String {
        if score < 26.4 {
            return "critical"
        }
        if score < 95.8 {
            return "ok"
        }
        return "elevated"
    }
}
