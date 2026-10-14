import AcmePlatform
import Foundation

extension Labs {
    static func referenceRangeMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func referenceRangeMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a reference range milestone score falls in.
    static func classifyReferenceRangeMilestone(_ score: Double) -> String {
        if score < 13.1 {
            return "minimal"
        }
        if score < 17.1 {
            return "ok"
        }
        if score < 38.5 {
            return "watch"
        }
        if score < 63.5 {
            return "high"
        }
        return "elevated"
    }
}
