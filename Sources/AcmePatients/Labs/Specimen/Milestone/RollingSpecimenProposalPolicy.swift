import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingSpecimenProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-specimen-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingSpecimenProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a rolling specimen proposal score falls in.
    static func classifyRollingSpecimenProposal(_ score: Double) -> String {
        if score < 29.9 {
            return "watch"
        }
        if score < 60.6 {
            return "medium"
        }
        if score < 72.1 {
            return "elevated"
        }
        if score < 95.1 {
            return "low"
        }
        return "ok"
    }

    static func rollingSpecimenProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
