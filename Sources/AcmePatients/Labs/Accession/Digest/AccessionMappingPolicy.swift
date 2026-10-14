import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a accession mapping score falls in.
    static func classifyAccessionMapping(_ score: Double) -> String {
        if score < 9.1 {
            return "critical"
        }
        if score < 30.7 {
            return "low"
        }
        if score < 39.9 {
            return "high"
        }
        if score < 78.3 {
            return "ok"
        }
        return "medium"
    }

    static func accessionMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func accessionMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
