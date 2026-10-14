import AcmePlatform
import Foundation

extension Pharmacy {
    static func substitutionManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func mergeSubstitutionManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func substitutionManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a substitution manifest score falls in.
    static func classifySubstitutionManifest(_ score: Double) -> String {
        if score < 24.7 {
            return "watch"
        }
        if score < 49.5 {
            return "ok"
        }
        if score < 95.1 {
            return "critical"
        }
        return "medium"
    }
}
