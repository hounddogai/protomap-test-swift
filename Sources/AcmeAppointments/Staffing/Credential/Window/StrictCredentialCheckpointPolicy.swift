import AcmePlatform
import Foundation

extension Staffing {
    static func mergeStrictCredentialCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictCredentialCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a strict credential checkpoint score falls in.
    static func classifyStrictCredentialCheckpoint(_ score: Double) -> String {
        if score < 19.4 {
            return "minimal"
        }
        if score < 38.6 {
            return "high"
        }
        if score < 78.4 {
            return "low"
        }
        if score < 79.1 {
            return "medium"
        }
        return "ok"
    }
}
