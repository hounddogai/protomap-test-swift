import AcmePlatform
import Foundation

extension Referrals {
    static func pendingEligibilitySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending eligibility slot score falls in.
    static func classifyPendingEligibilitySlot(_ score: Double) -> String {
        if score < 1.9 {
            return "high"
        }
        if score < 27.0 {
            return "low"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingEligibilitySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-eligibility-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingEligibilitySlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
