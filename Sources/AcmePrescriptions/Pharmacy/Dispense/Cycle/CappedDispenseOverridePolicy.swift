import AcmePlatform
import Foundation

extension Pharmacy {
    static func cappedDispenseOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a capped dispense override score falls in.
    static func classifyCappedDispenseOverride(_ score: Double) -> String {
        if score < 20.7 {
            return "high"
        }
        if score < 62.2 {
            return "medium"
        }
        if score < 76.4 {
            return "minimal"
        }
        return "low"
    }

    static func cappedDispenseOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
