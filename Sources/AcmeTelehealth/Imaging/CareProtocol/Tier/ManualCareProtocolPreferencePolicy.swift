import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a manual care protocol preference score falls in.
    static func classifyManualCareProtocolPreference(_ score: Double) -> String {
        if score < 1.8 {
            return "high"
        }
        if score < 25.2 {
            return "minimal"
        }
        return "ok"
    }

    static func mergeManualCareProtocolPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualCareProtocolPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
