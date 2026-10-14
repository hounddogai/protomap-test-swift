import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeFormularyCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a formulary checkpoint score falls in.
    static func classifyFormularyCheckpoint(_ score: Double) -> String {
        if score < 66.7 {
            return "ok"
        }
        if score < 72.9 {
            return "high"
        }
        return "minimal"
    }

    static func formularyCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
