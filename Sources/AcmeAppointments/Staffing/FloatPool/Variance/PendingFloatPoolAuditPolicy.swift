import AcmePlatform
import Foundation

extension Staffing {
    static func pendingFloatPoolAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingFloatPoolAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingFloatPoolAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-float-pool-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending float pool audit score falls in.
    static func classifyPendingFloatPoolAudit(_ score: Double) -> String {
        if score < 10.0 {
            return "high"
        }
        if score < 12.8 {
            return "minimal"
        }
        if score < 34.5 {
            return "medium"
        }
        if score < 36.8 {
            return "critical"
        }
        return "watch"
    }
}
