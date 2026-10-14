import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCareProtocolProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-care-protocol-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalCareProtocolProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a seasonal care protocol proposal score falls in.
    static func classifySeasonalCareProtocolProposal(_ score: Double) -> String {
        if score < 44.1 {
            return "minimal"
        }
        if score < 66.1 {
            return "high"
        }
        return "watch"
    }
}
