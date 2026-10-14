import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackShiftBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a fallback shift baseline score falls in.
    static func classifyFallbackShiftBaseline(_ score: Double) -> String {
        if score < 28.2 {
            return "ok"
        }
        if score < 37.9 {
            return "medium"
        }
        if score < 94.8 {
            return "low"
        }
        return "elevated"
    }
}
