import AcmePlatform
import Foundation

extension Labs {
    static func defaultResultManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a default result manifest score falls in.
    static func classifyDefaultResultManifest(_ score: Double) -> String {
        if score < 7.3 {
            return "low"
        }
        if score < 39.1 {
            return "critical"
        }
        if score < 39.7 {
            return "watch"
        }
        return "medium"
    }

    static func defaultResultManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
