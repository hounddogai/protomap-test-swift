import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a rolling read proposal score falls in.
    static func classifyRollingReadProposal(_ score: Double) -> String {
        if score < 11.4 {
            return "low"
        }
        if score < 98.0 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingReadProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-read-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingReadProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
