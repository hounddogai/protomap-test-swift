import AcmePlatform
import Foundation

extension Labs {
    static func mergeReferenceRangeForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a reference range forecast score falls in.
    static func classifyReferenceRangeForecast(_ score: Double) -> String {
        if score < 1.1 {
            return "ok"
        }
        if score < 47.5 {
            return "minimal"
        }
        return "critical"
    }
}
