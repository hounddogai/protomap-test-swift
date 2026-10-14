import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a default network record score falls in.
    static func classifyDefaultNetworkRecord(_ score: Double) -> String {
        if score < 19.5 {
            return "high"
        }
        if score < 87.6 {
            return "ok"
        }
        return "minimal"
    }

    static func mergeDefaultNetworkRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultNetworkRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-network-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultNetworkRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
