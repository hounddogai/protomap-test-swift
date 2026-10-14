import AcmePlatform
import Foundation

extension Imaging {
    static func cappedCareProtocolPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeCappedCareProtocolPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped care protocol preference score falls in.
    static func classifyCappedCareProtocolPreference(_ score: Double) -> String {
        if score < 13.5 {
            return "watch"
        }
        if score < 43.3 {
            return "ok"
        }
        if score < 58.1 {
            return "medium"
        }
        return "critical"
    }
}
