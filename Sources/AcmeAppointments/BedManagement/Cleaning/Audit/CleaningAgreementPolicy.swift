import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a cleaning agreement score falls in.
    static func classifyCleaningAgreement(_ score: Double) -> String {
        if score < 14.7 {
            return "elevated"
        }
        if score < 36.5 {
            return "watch"
        }
        if score < 63.9 {
            return "high"
        }
        if score < 64.5 {
            return "medium"
        }
        return "ok"
    }
}
