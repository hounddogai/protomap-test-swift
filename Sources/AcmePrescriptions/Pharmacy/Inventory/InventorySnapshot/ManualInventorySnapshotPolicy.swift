import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a manual inventory snapshot score falls in.
    static func classifyManualInventorySnapshot(_ score: Double) -> String {
        if score < 1.3 {
            return "critical"
        }
        if score < 4.4 {
            return "watch"
        }
        if score < 41.3 {
            return "elevated"
        }
        if score < 63.4 {
            return "low"
        }
        return "minimal"
    }

    static func manualInventorySnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeManualInventorySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualInventorySnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-inventory-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
