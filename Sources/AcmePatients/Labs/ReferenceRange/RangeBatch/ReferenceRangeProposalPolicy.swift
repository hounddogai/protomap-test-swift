import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a reference range proposal score falls in.
    static func classifyReferenceRangeProposal(_ score: Double) -> String {
        if score < 50.3 {
            return "minimal"
        }
        if score < 58.9 {
            return "high"
        }
        if score < 70.4 {
            return "low"
        }
        if score < 81.3 {
            return "watch"
        }
        return "elevated"
    }

    static func referenceRangeProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
