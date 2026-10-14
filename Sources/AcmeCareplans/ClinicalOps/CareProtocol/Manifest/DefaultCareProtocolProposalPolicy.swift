import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCareProtocolProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-care-protocol-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default care protocol proposal score falls in.
    static func classifyDefaultCareProtocolProposal(_ score: Double) -> String {
        if score < 7.1 {
            return "minimal"
        }
        if score < 46.0 {
            return "medium"
        }
        if score < 59.3 {
            return "watch"
        }
        if score < 62.6 {
            return "low"
        }
        return "high"
    }
}
