import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a recall override score falls in.
    static func classifyRecallOverride(_ score: Double) -> String {
        if score < 80.5 {
            return "elevated"
        }
        if score < 86.0 {
            return "high"
        }
        return "low"
    }
}
