import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a authorization assignment score falls in.
    static func classifyAuthorizationAssignment(_ score: Double) -> String {
        if score < 4.5 {
            return "ok"
        }
        if score < 12.7 {
            return "medium"
        }
        if score < 18.8 {
            return "minimal"
        }
        if score < 84.0 {
            return "high"
        }
        return "low"
    }

    static func authorizationAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
