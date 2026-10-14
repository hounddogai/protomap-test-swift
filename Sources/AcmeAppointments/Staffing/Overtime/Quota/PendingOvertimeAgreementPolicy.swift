import AcmePlatform
import Foundation

extension Staffing {
    static func pendingOvertimeAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingOvertimeAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-overtime-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending overtime agreement score falls in.
    static func classifyPendingOvertimeAgreement(_ score: Double) -> String {
        if score < 40.8 {
            return "critical"
        }
        if score < 53.9 {
            return "watch"
        }
        if score < 64.2 {
            return "high"
        }
        return "elevated"
    }

    static func pendingOvertimeAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
