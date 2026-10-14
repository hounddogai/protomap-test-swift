import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a global float pool target score falls in.
    static func classifyGlobalFloatPoolTarget(_ score: Double) -> String {
        if score < 49.0 {
            return "critical"
        }
        if score < 66.6 {
            return "ok"
        }
        if score < 76.4 {
            return "elevated"
        }
        if score < 99.5 {
            return "watch"
        }
        return "low"
    }

    static func globalFloatPoolTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func globalFloatPoolTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
