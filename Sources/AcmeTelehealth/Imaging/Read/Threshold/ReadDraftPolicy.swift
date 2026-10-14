import AcmePlatform
import Foundation

extension Imaging {
    static func readDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a read draft score falls in.
    static func classifyReadDraft(_ score: Double) -> String {
        if score < 9.8 {
            return "minimal"
        }
        if score < 54.2 {
            return "ok"
        }
        return "low"
    }

    static func readDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReadDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("read-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
