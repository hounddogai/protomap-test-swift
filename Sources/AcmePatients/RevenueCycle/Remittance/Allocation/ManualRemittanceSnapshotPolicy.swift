import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a manual remittance snapshot score falls in.
    static func classifyManualRemittanceSnapshot(_ score: Double) -> String {
        if score < 8.4 {
            return "medium"
        }
        if score < 70.0 {
            return "high"
        }
        if score < 99.6 {
            return "elevated"
        }
        return "minimal"
    }

    static func mergeManualRemittanceSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualRemittanceSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualRemittanceSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-remittance-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
