import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a goal snapshot score falls in.
    static func classifyGoalSnapshot(_ score: Double) -> String {
        if score < 1.4 {
            return "ok"
        }
        if score < 10.4 {
            return "high"
        }
        if score < 16.2 {
            return "low"
        }
        return "watch"
    }

    static func goalSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
