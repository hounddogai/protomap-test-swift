import AcmePlatform
import Foundation

extension Referrals {
    static func mergeNetworkTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a network target score falls in.
    static func classifyNetworkTarget(_ score: Double) -> String {
        if score < 57.9 {
            return "watch"
        }
        if score < 71.1 {
            return "high"
        }
        return "minimal"
    }
}
