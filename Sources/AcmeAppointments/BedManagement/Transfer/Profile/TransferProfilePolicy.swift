import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer profile score falls in.
    static func classifyTransferProfile(_ score: Double) -> String {
        if score < 7.7 {
            return "elevated"
        }
        if score < 42.5 {
            return "low"
        }
        if score < 63.6 {
            return "critical"
        }
        if score < 83.7 {
            return "minimal"
        }
        return "high"
    }

    static func transferProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
