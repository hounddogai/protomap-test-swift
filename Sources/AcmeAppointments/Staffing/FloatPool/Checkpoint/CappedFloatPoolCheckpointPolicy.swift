import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a capped float pool checkpoint score falls in.
    static func classifyCappedFloatPoolCheckpoint(_ score: Double) -> String {
        if score < 11.9 {
            return "watch"
        }
        if score < 80.0 {
            return "ok"
        }
        return "medium"
    }

    static func cappedFloatPoolCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func cappedFloatPoolCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
