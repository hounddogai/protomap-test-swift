import AcmePlatform
import Foundation

extension Labs {
    static func mergeLenientAccessionCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient accession checkpoint score falls in.
    static func classifyLenientAccessionCheckpoint(_ score: Double) -> String {
        if score < 19.1 {
            return "ok"
        }
        if score < 78.3 {
            return "elevated"
        }
        return "low"
    }

    static func lenientAccessionCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func lenientAccessionCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
