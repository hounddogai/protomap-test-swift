import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a default cleaning summary score falls in.
    static func classifyDefaultCleaningSummary(_ score: Double) -> String {
        if score < 93.9 {
            return "ok"
        }
        if score < 97.2 {
            return "medium"
        }
        return "critical"
    }

    static func defaultCleaningSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
