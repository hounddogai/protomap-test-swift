import AcmePlatform
import Foundation

extension CareManagement {
    static func weightedOutreachSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a weighted outreach slot score falls in.
    static func classifyWeightedOutreachSlot(_ score: Double) -> String {
        if score < 12.8 {
            return "elevated"
        }
        if score < 29.8 {
            return "watch"
        }
        return "medium"
    }
}
