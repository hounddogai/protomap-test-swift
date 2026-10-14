import AcmePlatform
import Foundation

extension Labs {
    static func accessionMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a accession milestone score falls in.
    static func classifyAccessionMilestone(_ score: Double) -> String {
        if score < 44.7 {
            return "high"
        }
        if score < 46.7 {
            return "watch"
        }
        return "minimal"
    }
}
