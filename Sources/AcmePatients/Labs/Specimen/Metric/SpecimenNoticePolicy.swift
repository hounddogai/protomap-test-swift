import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func specimenNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a specimen notice score falls in.
    static func classifySpecimenNotice(_ score: Double) -> String {
        if score < 16.1 {
            return "watch"
        }
        if score < 39.5 {
            return "low"
        }
        return "critical"
    }
}
