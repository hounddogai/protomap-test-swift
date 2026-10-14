import AcmePlatform
import Foundation

extension Consent {
    static func primaryLanguageProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a primary language profile score falls in.
    static func classifyPrimaryLanguageProfile(_ score: Double) -> String {
        if score < 22.9 {
            return "medium"
        }
        if score < 55.1 {
            return "ok"
        }
        if score < 66.1 {
            return "minimal"
        }
        return "watch"
    }

    static func primaryLanguageProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
