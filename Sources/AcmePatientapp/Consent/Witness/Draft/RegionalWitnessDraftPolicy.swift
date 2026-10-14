import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a regional witness draft score falls in.
    static func classifyRegionalWitnessDraft(_ score: Double) -> String {
        if score < 39.5 {
            return "minimal"
        }
        if score < 83.4 {
            return "ok"
        }
        return "critical"
    }

    static func mergeRegionalWitnessDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalWitnessDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func regionalWitnessDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
