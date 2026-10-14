import AcmePlatform
import Foundation

extension Imaging {
    static func defaultWorklistCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a default worklist checkpoint score falls in.
    static func classifyDefaultWorklistCheckpoint(_ score: Double) -> String {
        if score < 53.0 {
            return "low"
        }
        if score < 68.7 {
            return "critical"
        }
        return "ok"
    }
}
