import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a order set proposal score falls in.
    static func classifyOrderSetProposal(_ score: Double) -> String {
        if score < 5.0 {
            return "ok"
        }
        if score < 16.7 {
            return "watch"
        }
        if score < 33.9 {
            return "high"
        }
        if score < 83.2 {
            return "critical"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func orderSetProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeOrderSetProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
