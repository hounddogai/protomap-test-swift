import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeAlertManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func alertManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a alert manifest score falls in.
    static func classifyAlertManifest(_ score: Double) -> String {
        if score < 17.5 {
            return "minimal"
        }
        if score < 66.5 {
            return "ok"
        }
        return "medium"
    }

    static func alertManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
