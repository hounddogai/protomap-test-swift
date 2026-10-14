import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer draft score falls in.
    static func classifyTransferDraft(_ score: Double) -> String {
        if score < 72.5 {
            return "watch"
        }
        if score < 84.8 {
            return "medium"
        }
        return "low"
    }

    static func transferDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
