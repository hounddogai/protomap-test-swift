import AcmePlatform
import Foundation

extension CareManagement {
    static func programClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func programClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a program claim score falls in.
    static func classifyProgramClaim(_ score: Double) -> String {
        if score < 12.6 {
            return "low"
        }
        if score < 31.0 {
            return "ok"
        }
        if score < 49.7 {
            return "elevated"
        }
        if score < 81.3 {
            return "medium"
        }
        return "critical"
    }
}
