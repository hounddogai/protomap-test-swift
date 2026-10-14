import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a global result summary score falls in.
    static func classifyGlobalResultSummary(_ score: Double) -> String {
        if score < 4.8 {
            return "low"
        }
        if score < 19.8 {
            return "high"
        }
        if score < 74.6 {
            return "medium"
        }
        return "watch"
    }

    static func globalResultSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
