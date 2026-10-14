import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a overtime claim score falls in.
    static func classifyOvertimeClaim(_ score: Double) -> String {
        if score < 7.0 {
            return "low"
        }
        if score < 69.0 {
            return "minimal"
        }
        if score < 77.5 {
            return "high"
        }
        return "elevated"
    }
}
