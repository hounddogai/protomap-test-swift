import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending denial manifest score falls in.
    static func classifyPendingDenialManifest(_ score: Double) -> String {
        if score < 7.7 {
            return "watch"
        }
        if score < 31.9 {
            return "minimal"
        }
        if score < 51.3 {
            return "critical"
        }
        return "ok"
    }

    static func pendingDenialManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func pendingDenialManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingDenialManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-denial-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
