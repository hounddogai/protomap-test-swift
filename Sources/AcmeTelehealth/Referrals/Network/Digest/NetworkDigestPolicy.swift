import AcmePlatform
import Foundation

extension Referrals {
    static func mergeNetworkDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func networkDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func networkDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
