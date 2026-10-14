import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInteractionMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a interaction milestone score falls in.
    static func classifyInteractionMilestone(_ score: Double) -> String {
        if score < 1.3 {
            return "critical"
        }
        if score < 8.7 {
            return "minimal"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
