import AcmePlatform
import Foundation

extension Pharmacy {
    static func weightedRecallNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedRecallNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-recall-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted recall notice score falls in.
    static func classifyWeightedRecallNotice(_ score: Double) -> String {
        if score < 67.3 {
            return "elevated"
        }
        if score < 74.1 {
            return "medium"
        }
        return "low"
    }

    static func weightedRecallNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
