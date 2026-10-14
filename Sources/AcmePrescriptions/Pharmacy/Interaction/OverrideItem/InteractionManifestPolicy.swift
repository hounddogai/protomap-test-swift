import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func interactionManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
