import AcmePlatform
import Foundation

extension Pharmacy {
    static func weightedFormularyEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeWeightedFormularyEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted formulary entry score falls in.
    static func classifyWeightedFormularyEntry(_ score: Double) -> String {
        if score < 6.6 {
            return "low"
        }
        if score < 51.3 {
            return "elevated"
        }
        return "minimal"
    }
}
