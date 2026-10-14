import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a recall slot score falls in.
    static func classifyRecallSlot(_ score: Double) -> String {
        if score < 49.6 {
            return "medium"
        }
        if score < 68.6 {
            return "critical"
        }
        return "minimal"
    }
}
