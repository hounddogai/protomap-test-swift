import AcmePlatform
import Foundation

extension RevenueCycle {
    static func legacyAuthorizationSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAuthorizationSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-authorization-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyAuthorizationSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func legacyAuthorizationSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
