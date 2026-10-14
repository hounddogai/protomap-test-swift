import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func isolationVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a isolation variance score falls in.
    static func classifyIsolationVariance(_ score: Double) -> String {
        if score < 75.9 {
            return "critical"
        }
        if score < 76.5 {
            return "minimal"
        }
        if score < 80.5 {
            return "ok"
        }
        if score < 96.3 {
            return "low"
        }
        return "medium"
    }
}
