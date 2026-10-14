import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeRegionalCensusRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional census request score falls in.
    static func classifyRegionalCensusRequest(_ score: Double) -> String {
        if score < 9.8 {
            return "watch"
        }
        if score < 40.1 {
            return "critical"
        }
        return "elevated"
    }

    static func regionalCensusRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
