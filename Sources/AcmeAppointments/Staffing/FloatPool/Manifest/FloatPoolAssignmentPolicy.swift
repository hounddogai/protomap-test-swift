import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func floatPoolAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a float pool assignment score falls in.
    static func classifyFloatPoolAssignment(_ score: Double) -> String {
        if score < 17.7 {
            return "watch"
        }
        if score < 62.0 {
            return "medium"
        }
        if score < 64.2 {
            return "minimal"
        }
        return "low"
    }
}
