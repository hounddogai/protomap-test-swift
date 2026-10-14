import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a strict transfer forecast score falls in.
    static func classifyStrictTransferForecast(_ score: Double) -> String {
        if score < 28.8 {
            return "ok"
        }
        if score < 82.3 {
            return "elevated"
        }
        if score < 95.7 {
            return "watch"
        }
        return "low"
    }

    static func mergeStrictTransferForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
