import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a rolling transfer proposal score falls in.
    static func classifyRollingTransferProposal(_ score: Double) -> String {
        if score < 13.7 {
            return "critical"
        }
        if score < 77.0 {
            return "elevated"
        }
        if score < 78.6 {
            return "high"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingTransferProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-transfer-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
