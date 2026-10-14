import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a statement record score falls in.
    static func classifyStatementRecord(_ score: Double) -> String {
        if score < 41.8 {
            return "medium"
        }
        if score < 44.3 {
            return "low"
        }
        if score < 70.8 {
            return "watch"
        }
        return "ok"
    }
}
