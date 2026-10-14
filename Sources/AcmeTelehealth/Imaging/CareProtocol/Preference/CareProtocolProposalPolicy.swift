import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careProtocolProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
