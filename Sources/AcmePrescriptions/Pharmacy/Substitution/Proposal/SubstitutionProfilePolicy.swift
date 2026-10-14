import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a substitution profile score falls in.
    static func classifySubstitutionProfile(_ score: Double) -> String {
        if score < 9.0 {
            return "critical"
        }
        if score < 75.1 {
            return "watch"
        }
        return "elevated"
    }

    static func substitutionProfileSpan(_ start: Int, end: Int) -> Int {
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
