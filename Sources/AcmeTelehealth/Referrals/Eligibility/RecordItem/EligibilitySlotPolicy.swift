import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilitySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func eligibilitySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
