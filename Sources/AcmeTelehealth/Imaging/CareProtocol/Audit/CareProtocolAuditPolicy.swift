import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a care protocol audit score falls in.
    static func classifyCareProtocolAudit(_ score: Double) -> String {
        if score < 39.5 {
            return "low"
        }
        if score < 87.5 {
            return "medium"
        }
        if score < 91.9 {
            return "minimal"
        }
        return "elevated"
    }

    static func careProtocolAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
